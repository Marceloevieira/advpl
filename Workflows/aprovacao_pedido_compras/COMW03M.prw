#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'


/*/{Protheus.doc} COMW03M
 Funcao prepara a inicializacao do workflow de aprovaçao de compras
@type function
@version 1.0 
@author PROTHEUS
@since 30/04/2021
/*/
User Function COMW03M()

	Local aArea    := GetArea()
	Local aAreaC7  := SC7->(GetArea())



	DbSelectArea("SC7")
	SC7->(DbSetOrder(1))//C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN

	FWMsgRun(, {|oSay| W03MINIC(oSay) }, 'Processando o Envio para aprovação', 'Aguarde, processando a rotina' )

	RestArea(aAreaC7)
	RestArea(aArea)

return


/*/{Protheus.doc} W03MINIC
 Funcao para leitura da alçada e envio dos emails para os aprovadores.
@type function
@version 1.0
@author PROTHEUS
@since 30/04/2021
@param oSay, object, Tsay para fwmsgrun

/*/
Static Function W03MINIC(oSay)

	Local aArea       := GetArea()
	Local aAreaAI     := SAI->(GetArea())
	Local aAreaAk     := SAK->(GetArea())
	Local aAreaA2     := SA2->(GetArea())
	Local aAreaE4     := SE4->(GetArea())
	Local aAreaCTT    := CTT->( GetArea() )
	Local cPCNum      := ""
	Local cUsAprov    := ""
	Local cMailID     := ""
	Local cPasta      := "pedido_compras"
	Local cSubject    := "Pedido de Compra (Nº " + SC7->C7_NUM + ")"
	Local cLogoSrc    := GetNewPar( "MV_XLOGOWF" , "https://i.imgur.com/JiAa84l.png" )
	Local cStatus     := "02" // CR_STATUS='02' - Aguardando Liberação do usuário
	Local cMsgUsr     := ""
	Local cEmail      := ""
	Local lExAprov    := SuperGetMV("MV_EXAPROV",.F.,.F.)
	Local cTipoCR     := Iif(MtExistDBM('IP',SC7->C7_NUM,,,lExAprov),"IP","PC")
	Local oProcess    := NIL
	Private cAliasTmp := GetNextAlias()


	DbSelectArea("SCR")
	SCR->(DbSetOrder(1))
	SCR->(DbGotop())
	If SCR->(DbSeek(xFilial("SCR") + cTipoCR + SC7->C7_NUM  ))

		//--------------------------------------------------------------+
		// Fornecedor  							                        |
		//--------------------------------------------------------------+
		DbSelectArea("SA2")
		SA2->(DbSetOrder(1))
		SA2->(DbSeek(xFilial("SA2") + SC7->(C7_FORNECE+C7_LOJA)))

		//--------------------------------------------------------------+
		// Condição pagamento					                        |
		//--------------------------------------------------------------+
		dbSelectArea('SE4')
		SE4->( dbSetOrder(1) )
		SE4->(DbSeek(xFilial("SE4") + SC7->C7_COND ))

		//--------------------------------------------------------------+
		// Produto								                        |
		//--------------------------------------------------------------+
		dbSelectArea('SB1')
		SB1->( dbSetOrder(1) )

		//--------------------------------------------------------------+
		// Produto								                        |
		//--------------------------------------------------------------+
		dbSelectArea('SB2')
		SB2->( dbSetOrder(1) )

		//--------------------------------------------------------------+
		// Solicitantes							                        |
		//--------------------------------------------------------------+
		DbSelectArea("SAI")
		SAI->(DbSetOrder(2))//AI_FILIAL+AI_USER

		//--------------------------------------------------------------+
		// Aprovadores							                        |
		//--------------------------------------------------------------+
		DbSelectArea("SAK")
		SAK->(DbSetOrder(1))//AK_FILIAL+AK_COD

		While SCR->(!Eof()) .And. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) = xFilial('SCR') + cTipoCR + SC7->C7_NUM

			If SCR->CR_STATUS = cStatus


				cPCNum    := SC7->C7_NUM
				cUsAprov  := SCR->CR_USER
				cEmail    := UsrRetMail(SCR->CR_USER)
				cMsgUsr   +=  cEmail + CRLF

				oProcess := TWFProcess():New( "PCCOM", "Pedido de Compras" )
				oProcess:NewTask( "Aprovação", "\WORKFLOW\PEDIDO_COMPRAS\WFPCAPROV.HTM" )
				oProcess:cSubject := cSubject
				oProcess:bReturn := "U_W03MRETU()"
				oProcess:bTimeOut := {{"U_W03MTMOU()",0, 0, 10 }}
				oHTML := oProcess:oHTML

				//--------------------------------------------------------------+
				// Logo   	-MV_WFIMAGE  .F.			                        |
				//--------------------------------------------------------------+
				oHtml:ValByName( "LOGOEMP" , cLogoSrc    )
				oHtml:ValByName( "NOMEEMP" , FWEmpName(cEmpAnt) )


				//--------------------------------------------------------------+
				// Dados da Solicitacao                                         |
				//--------------------------------------------------------------+
				If oHtml:ExistField(1, "WFPCNUM")
					oHtml:ValByName("WFPCNUM",  SC7->C7_NUM	)
				EndIf
				If oHtml:ExistField(1, "WFCOMPRADOR")
					oHtml:ValByName("WFCOMPRADOR",  Capital(AllTrim(UsrFullName(SC7->C7_USER))))
				EndIf
				If oHtml:ExistField(1, "WFEMISSAO")
					oHtml:ValByName("WFEMISSAO",  Dtoc(SC7->C7_EMISSAO)	)
				EndIf
				If oHtml:ExistField(1, "WFFORNECE")
					oHtml:ValByName("WFFORNECE",  AllTrim(SA2->A2_NOME)	)
				EndIf
				If oHtml:ExistField(1, "WFCONDPAG")
					oHtml:ValByName("WFCONDPAG",  AllTrim(SE4->E4_DESCRI)	)
				EndIf
				If oHtml:ExistField(1, "WFFILENTREG")
					oHtml:ValByName("WFFILENTREG",  SC7->C7_FILENT	)
				EndIf
				If oHtml:ExistField(1, "WFMOEDA")
					oHtml:ValByName("WFMOEDA",  SC7->C7_MOEDA	)
				EndIf
				If oHtml:ExistField(1, "WFTAXA")
					oHtml:ValByName("WFTAXA",  SC7->C7_TXMOEDA	)
				EndIf

				oProcess:fDesc := "Pedido de Compras No " + cPCNum

				If cTipoCR = 'IP'

					BeginSql Alias cAliasTmp
					SELECT SC7.R_E_C_N_O_ AS RECSC7 
					FROM %TABLE:SCR% SCR 
					INNER JOIN %TABLE:DBM% DBM ON 
						 DBM.DBM_FILIAL= %xFilial:DBM% AND 
						 SCR.CR_TIPO=DBM.DBM_TIPO      AND 
						 SCR.CR_NUM=DBM.DBM_NUM        AND 
						 SCR.CR_GRUPO=DBM.DBM_GRUPO    AND 
						 SCR.CR_ITGRP=DBM.DBM_ITGRP    AND 
						 SCR.CR_USER=DBM.DBM_USER      AND 
						 SCR.CR_USERORI=DBM.DBM_USEROR AND 
						 SCR.CR_APROV=DBM.DBM_USAPRO   AND 
						 SCR.CR_APRORI=DBM.DBM_USAPOR  AND 
						 DBM.%NOTDEL%
					INNER JOIN %TABLE:SC7% SC7 ON 
						 SC7.C7_FILIAL = %xFilial:SC7% AND
						 SC7.C7_NUM    = DBM.DBM_NUM   AND 
						 SC7.C7_ITEM   = DBM.DBM_ITEM  AND 
						 SC7.%NOTDEL%
					 WHERE SCR.CR_FILIAL= %xFilial:SCR% AND 		
					 SCR.CR_TIPO = 'IP' 				AND 
					 SCR.CR_NUM   = %Exp:SCR->CR_NUM%   AND
					 SCR.CR_APROV = %Exp:SCR->CR_APROV% AND
					 SCR.D_E_L_E_T_=' ' 
					EndSql


					If (cAliasTmp)->(!Eof())

						While (cAliasTmp)->(!Eof())

							SC7->(DbGoTo( (cAliasTmp)->(RECSC7) ))

							W03MADDIT(@oHtml)


							(cAliasTmp)->(DbSkip())
						EndDo
					EndIf

					(cAliasTmp)->(DbCloseArea())

				Else

					SC7->(DbSetOrder(1))
					SC7->(DbSeek(xFilial('SC7')+cPCNum))


					While SC7->(!Eof()) .and. SC7->(C7_FILIAL+C7_NUM) =  xFilial('SC7') + cPCNum

						W03MADDIT(@oHtml)

						SC7->(dbSkip())
					Enddo
					SC7->(DbSeek(xFilial('SC7')+cPCNum))
				EndIf


				oProcess:ClientName( Subs(cUsuario,7,15))
				oProcess:cTo := cPasta  // Destinatario do Email.

				//Adiciona parametros de retorno
				Aadd( oProcess:aParams, SCR->(CR_FILIAL+CR_TIPO+CR_NUM+CR_APROV)   )
				Aadd( oProcess:aParams, SC7->(C7_FILIAL+C7_NUM)  )

				cMailID := oProcess:Start()

				CONOUT("Rastreando:"+oProcess:fProcCode)



				//--------------------------------------------------------------+
				//   Template do email                      				    |
				//--------------------------------------------------------------+
				oProcess:NewTask(cSubject, "\WORKFLOW\PEDIDO_COMPRAS\WFLINK.HTM" )

				//--------------------------------------------------------------+
				// ASSUNTO DO E-MAIL, REFERENTE AO PROCESSO                     |
				//--------------------------------------------------------------+
				oProcess:cSubject := cSubject

				//--------------------------------------------------------------+
				//  Endereço eletrônico do destinatário.                        |
				//--------------------------------------------------------------+
				oProcess:cTo := cEmail
				oProcess:ohtml:ValByName("LOGOEMP"  ,cLogoSrc)
				oProcess:ohtml:ValByName("NOMEEMP"  ,FWEmpName(cEmpAnt))
				oProcess:ohtml:ValByName("WCONTATO" , Capital(AllTrim(UsrFullName(cUsAprov))))
				oProcess:ohtml:ValByName("WNUM"     , SC7->C7_NUM )


				IF !WFGetMV( "MV_WFWEBEX", .F. )
					oProcess:ohtml:ValByName("proc_link"    ,"http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080"     )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
					oProcess:ohtml:ValByName("link_int"     ,"http://" + ALLTRIM(WFGetMV( "MV_XWFINTE", "localhost:8080"     )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
				Else
					oProcess:ohtml:ValByName("proc_link","http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080" )) +"/w_wfhttpret.apw?ProcID=" + cPasta + "/" + cMailID + ".htm")
				Endif


				oProcess:Start()
				FreeObj( oProcess )
				//StartJob( "WFLauncher", GetEnvServer(), .F., { "WFSndMsgAll", { cEmpAnt, cFilAnt } } )

			EndIf

			SCR->(DBSkip())
		EndDo

		If !Empty(cMsgUsr) .And. !IsBlind()

			cMsgUsr  := "Email enviado ao aprovadores : "	+CRLF + cMsgUsr
			cMsgUsr  := "Pedido Nr: " + SC7->C7_NUM  + CRLF + cMsgUsr
			MessageBox( cMsgUsr , "Envio de Email", 0)

		EndIf

	EndIf



	RestArea( aAreaCTT )
	RestArea( aAreaE4  )
	RestArea( aAreaA2 )
	RestArea( aAreaAk )
	RestArea( aAreaAI )
	RestArea( aArea )

Return



/*/{Protheus.doc} W03MTMOU
 funcao para timeout do workflow
@type function
@version  1.0
@author PROTHEUS
@since 30/04/2021
@param oProcess, object, TWFProcess

/*/
User Function W03MTMOU( oProcess )
	ConOut("Funcao de TIMEOUT executada")
	oProcess:Finish()  //Finalizo o Processo
Return



/*/{Protheus.doc} W03MRETU
 Funcao de retorno do workflow,responsavel por carregar o modelo mata094 para aprovaçao da alçada
@type function
@version 1.0 
@author PROTHEUS
@since 30/04/2021
@param oProcess, object, TWFProcess
/*/
User Function W03MRETU(oProcess)


	Local aAreaSC7  := {}
	Local cChaveSCR := oProcess:aParams[1]
	Local cChaveSC7 := oProcess:aParams[2]
	Local cAprov    := ""
	Local cWMotivo  := ""
	Local oModel094 := nil


	FWLogMsg('INFO',, 'W03MRETU', FunName(), '', '01', "Executando processo de retorno do workflow.", 0, 0, {})

	//--------------------------------------------------------------+
	// Verifica a existencia das referencias no html                |
	//--------------------------------------------------------------+
	If oProcess:oHtml:ExistField(2, "WAPROVA") .And. oProcess:oHtml:ExistField(2, "WMOTIVO")


		cAprov  :=  oProcess:oHtml:RetByName('WAPROVA')
		cAprov  :=  oProcess:oHtml:RetByName('WMOTIVO')


		DbSelectArea("SC7")
		SC7->(DbSetOrder(1))
		If SC7->(DBSeek(cChaveSC7))

			aAreaSC7 := SC7->(GetArea())

			DBSelectarea("SCR")
			DBSetorder(3)
			If SCR->(DBSeek(cChaveSCR))

				__cUserId := SCR->CR_USER
				cUserName := UsrRetName(__cUserId)

				if cAprov <> 'S'

					A094SetOp( '005' ) //-- Seta operacao de Rejeição de documentos

					oModel094 := FWLoadModel('MATA094')
					oModel094:SetOperation(MODEL_OPERATION_UPDATE)

					If oModel094:Activate()

						If Empty( cWMotivo )
							cWMotivo := "Motivo não informada no workflow"
						EndIf

						oModel094:GetModel("FieldSCR"):SetValue( 'CR_OBS' , cWMotivo )

						If oModel094:VldData()
							oModel094:CommitData()
							FWLogMsg('INFO',, 'W03MRETU', FunName(), '', '01', "Pedido Rejeitado.", 0, 0, {})
							RestArea(aAreaSC7)
							W03MNOTI(cAprov, SC7->C7_NUM,cWMotivo)
						Else
							Conout(oModel094:GetErrorMessage()[6])
							Conout(oModel094:GetErrorMessage()[7])
						EndIf
					Else
						Conout(oModel094:GetErrorMessage()[6])
						Conout(oModel094:GetErrorMessage()[7])
					EndIf
				Else

					A094SetOp( '001' ) //-- Seta operacao de aprovacao de documentos

					oModel094 := FWLoadModel('MATA094')
					oModel094:SetOperation(MODEL_OPERATION_UPDATE)

					If oModel094:Activate()

						oModel094:GetModel("FieldSCR"):SetValue( 'CR_OBS' , cWMotivo )

						If oModel094:VldData()
							oModel094:CommitData()

							FWLogMsg('INFO',, 'W03MRETU', FunName(), '', '01', "Pedido Aprovado.", 0, 0, {})

							RestArea(aAreaSC7)

							If SC7->C7_CONAPRO = 'B'
								If ARPRPRXNVL(SCR->CR_NIVEL)
									W03MINIC()
								EndIf
							ElseIf SC7->C7_CONAPRO = 'L'
								W03MNOTI(cAprov, SC7->C7_NUM,cWMotivo)
							EndIf
						Else
							Conout(oModel094:GetErrorMessage()[6])
							Conout(oModel094:GetErrorMessage()[7])
						EndIf
					Else
						Conout(oModel094:GetErrorMessage()[6])
						Conout(oModel094:GetErrorMessage()[7])
					EndIf
				Endif
			Else
				FWLogMsg('INFO',, 'W03MRETU', FunName(), '', '01', 'Não foi possivel localizar a alçada.', 0, 0, {})
			Endif
			FWLogMsg('INFO',, 'W03MRETU', FunName(), '', '01', 'Não foi possivel localizar o pedido.', 0, 0, {})
		Endif

	EndIf

	WFConout( "Finalizando Retorno" ,,,,.T.,"WF_PC-W03MRETU" )

Return




/*/{Protheus.doc} W03MADDIT
Funcao para carregar os itens do pedido para o modelo 
@type function
@version 1.0
@author PROTHEUS
@since 30/04/2021
@param oHtml, object, TWFHTML
/*/
Static Function W03MADDIT(oHtml)



	If SB1->( MsSeek(xFilial('SB1')+ SC7->C7_PRODUTO) )
		If SB2->(MsSeek(xFilial("SB2") + SC7->(C7_PRODUTO+C7_LOCAL) ))

			//--------------------------------------------------------------+
			// Itens da Solicitacao					                        |
			//--------------------------------------------------------------+
			AADD( (oHtml:ValByName( "IT.WFITEM" ))    ,SC7->C7_ITEM )
			AADD( (oHtml:ValByName( "IT.WFPRODUTO" )) ,SC7->C7_PRODUTO )
			AADD( (oHtml:ValByName( "IT.WFDESCRIC" )) ,SC7->C7_DESCRI )
			AADD( (oHtml:ValByName( "IT.WFSLDOATU" )) ,TRANSFORM( SB2->B2_QATU,PesqPict("SB2","B2_QATU") ) )
			AADD( (oHtml:ValByName( "IT.WFUNIDMED" )) ,SC7->C7_UM    )
			AADD( (oHtml:ValByName( "IT.WFARMAZEM" )) ,SC7->C7_LOCAL )
			AADD( (oHtml:ValByName( "IT.WFQUANTID" )) ,TRANSFORM( SC7->C7_QUANT ,PesqPict("SC7","C7_QUANT")  )   )
			AADD( (oHtml:ValByName( "IT.WFPRCUNID" )) ,TRANSFORM( SC7->C7_PRECO ,PesqPict("SC7","C7_PRECO") )   )
			AADD( (oHtml:ValByName( "IT.WFTOTIT" ))   ,TRANSFORM( SC7->C7_TOTAL ,PesqPict("SC7","C7_TOTAL") )   )

		EndIf
	EndIf

Return



/*/{Protheus.doc} W03MNOTI
 Funcao responsavel por realizar  a notificaçao do resultado da alçada
@type function
@version  1.0
@author PROTHEUS
@since 30/04/2021
@param cAprov, character, S - APROVAR | N - REJEITAR
@param cPcNum, character,  
@param cMotivo, character, motivo da aprovaçao / recusa
/*/
Static Function W03MNOTI(cAprov,cPcNum,cMotivo)




Return



/*/{Protheus.doc} ARPRPRXNVL
Funcao para verificar se existe nivel superior
@type function
@version  1.0
@author PROTHEUS
@since 20/01/2021
@param cNivel, character, CR_NIVEL
/*/
Static Function ARPRPRXNVL(cNivel)

	Local aArea    := GetArea()
	Local aAreaSCR := SCR->(GetArea())
	Local lRet     := .F.
	Local lExAprov := SuperGetMV("MV_EXAPROV",.F.,.F.)
	Local cTipoCR  := Iif(MtExistDBM('IP',SC7->C7_NUM,,,lExAprov),"IP","PC")

	DbSelectArea("SCR")
	SCR->(DbSetOrder(1))
	If SCR->(DbSeek(xfilial("SCR") + cTipoCR + SC7->C7_NUM ))

		While SCR->(!Eof()) .And. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) = xfilial("SCR") + cTipoCR + SC7->C7_NUM

			If SCR->CR_NIVEL > cNivel
				lRet := .T.
				EXIT
			EndIf

			SCR->(DbSkip())
		EndDo
	EndIf

	RestArea(aAreaSCR)
	RestArea(aArea)

Return lRet
