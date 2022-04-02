#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} COMW02M
//TODO Funçao para enviar SC bloqueada para o aprovador por wf.
@author PROTHEUS
@since 02/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
user function COMW02M()

	Local aArea    := GetArea()
	Local aAreaC1  := SC1->(GetArea())

	Local cNumSol  := PARAMIXB[1]


	DbSelectArea("SC1")
	SC1->(DbSetOrder(1))//C1_FILIAL+C1_NUM+C1_ITEM+C1_ITEMGRD

	FWMsgRun(, {|oSay| SSCINICIAR(oSay) }, 'Processando o Envio para aprovação', 'Aguarde, processando a rotina' ) 

	RestArea(aAreaC1)
	RestArea(aArea)

return


/*/{Protheus.doc} SSCINICIAR
//TODO Inicia o process ode workflow de aprovacao
@author Marcelo Evangelista
@since 23/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
Static Function SSCINICIAR(oSay)

	Local aArea       := GetArea()
	Local aAreaAI     := SAI->(GetArea())
	Local aAreaAk     := SAK->(GetArea())
	Local aAreaA2     := SA2->(GetArea())
	Local aAreaE4     := SE4->(GetArea())
	Local aAreaCTT    := CTT->( GetArea() )
	Local aAreaTmp    := {}
	Local cSCNum      := ""
	Local cUsAprov    := ""
	Local cCCAtu      := ""
	Local cMailID     := ""
	Local cPasta      := "solicitacao_compras"
	Local cSubject    := "Solicitação de Compra (Nº " + SC1->C1_NUM + ")"
	Local cLogoSrc    := GetNewPar( "MV_XLOGOWF" , "https://i.imgur.com/JiAa84l.png" )
	Local oProcess    := NIL 
	Private cAliasTmp := GetNextAlias()

	//--------------------------------------------------------------+
	// Fornecedor  							                        |
	//--------------------------------------------------------------+
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))
	SA2->(DbSeek(xFilial("SA2") + SC1->(C1_FORNECE+C1_LOJA)))

	//--------------------------------------------------------------+
	// Centro de Custo						                        |
	//--------------------------------------------------------------+
	dbSelectArea('CTT')
	CTT->( DbSetOrder(1) )
	CTT->( DbSeek(xFilial('CTT')+SC1->C1_CC) )

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

	BeginSql Alias cAliasTmp

		SELECT 
		C1_FILIAL,
		C1_NUM,
		C1_ITEM,
		C1_CC,
		DBM_USER 

		FROM %Table:SCR%  SCR
		INNER JOIN %Table:DBM% DBM ON DBM.DBM_FILIAL = SCR.CR_FILIAL
		AND DBM.DBM_NUM    = SCR.CR_NUM
		AND DBM.DBM_TIPO   = SCR.CR_TIPO
		AND DBM.DBM_GRUPO  = SCR.CR_GRUPO
		AND DBM.DBM_ITGRP  = SCR.CR_ITGRP
		AND DBM.DBM_USAPRO = SCR.CR_APROV
		AND DBM.DBM_USAPOR = SCR.CR_APRORI
		AND DBM.%NOTDEL% 
		INNER JOIN %Table:SC1% SC1 ON C1_FILIAL = DBM_FILIAL
		AND C1_NUM = DBM_NUM
		AND C1_ITEM = DBM_ITEM
		AND SC1.%NOTDEL% 
		WHERE SCR.CR_FILIAL = %xFilial:SCR%
		AND SCR.CR_TIPO   = 'SC'
		AND SC1.C1_APROV = 'B'
		AND SCR.CR_NUM    = %Exp:SC1->C1_NUM%
		AND SCR.%NOTDEL%
		ORDER BY SC1.C1_FILIAL,SC1.C1_CC,DBM.DBM_USER,SC1.C1_NUM,SC1.C1_ITEM

	EndSql

	memowrite("c:\temp\COMW02M.SQL",GetLastQuery()[2])

	If (cAliasTmp)->(!Eof())
		While (cAliasTmp)->(!Eof())

			If SC1->(MsSeek(xFilial("SC1")+ (cAliasTmp)->(C1_NUM+C1_ITEM)  ))



				cSCNum      := SC1->C1_NUM
				cCCAtu      := (cAliasTmp)->(C1_CC)
				cUsAprov    := (cAliasTmp)->DBM_USER 


				oProcess := TWFProcess():New( "SOLCOM", "Solicitacao de Compras" )
				oProcess:NewTask( "Aprovação", "\WORKFLOW\SOLICITACAO_COMPRAS\WFSCAPROV.HTM" )
				oProcess:cSubject := cSubject 
				oProcess:bReturn := "U_SSCRetorno()"
				oProcess:bTimeOut := {{"U_SSCTimeOut()",0, 0, 10 }}
				oHTML := oProcess:oHTML

				//--------------------------------------------------------------+
				// Logo   	-MV_WFIMAGE  .F.			                        |
				//--------------------------------------------------------------+	
				oHtml:ValByName( "LOGOEMP" , cLogoSrc    )
				oHtml:ValByName( "NOMEEMP" , FWEmpName(cEmpAnt) )


				//--------------------------------------------------------------+
				// Dados da Solicitacao                                         |
				//--------------------------------------------------------------+
				If oHtml:ExistField(1, "WSCNUM")
					oHtml:ValByName("WSCNUM",  SC1->C1_NUM	)
				EndIf
				If oHtml:ExistField(1, "WSSOLICIT")
					oHtml:ValByName("WSSOLICIT",  SC1->C1_SOLICIT	)
				EndIf
				If oHtml:ExistField(1, "WSEMISSAO")
					oHtml:ValByName("WSEMISSAO",  Dtoc(SC1->C1_EMISSAO)	)
				EndIf
				If oHtml:ExistField(1, "WUNIDREQ")
					oHtml:ValByName("WUNIDREQ",  SC1->C1_UNIDREQ	)
				EndIf
				If oHtml:ExistField(1, "WCODCOMP")
					oHtml:ValByName("WCODCOMP",  SC1->C1_CODCOMP	)
				EndIf
				If oHtml:ExistField(1, "WFILENT")
					oHtml:ValByName("WFILENT",  SC1->C1_FILENT	)
				EndIf
				If oHtml:ExistField(1, "WSCCC")
					oHtml:ValByName("WSCCC",  SC1->C1_CC	)
				EndIf


				oProcess:fDesc := "Solicitação de Compras No " + cSCNum

				aAreaTmp := SC1->(GetArea())

				While (cAliasTmp)->(!Eof()) .and. (cAliasTmp)->(C1_NUM+C1_CC+DBM_USER ) == cSCNum + cCCAtu + cUsAprov

					If  SC1->(MsSeek(xFilial("SC1") + (cAliasTmp)->(C1_NUM+C1_ITEM))) .And. SC1->C1_APROV == 'B'
						If SB1->( MsSeek(xFilial('SB1')+ SC1->C1_PRODUTO) ) 
							If SB2->(MsSeek(xFilial("SB2") + SC1->(C1_PRODUTO+C1_LOCAL) ))

								//--------------------------------------------------------------+
								// Itens da Solicitacao					                        |
								//--------------------------------------------------------------+
								AADD( (oHtml:ValByName( "WF.WITEM" ))     ,SC1->C1_ITEM )		
								AADD( (oHtml:ValByName( "WF.WPRODUTO" ))  ,SC1->C1_PRODUTO )		
								AADD( (oHtml:ValByName( "WF.WDESCPROD" )) ,SC1->C1_DESCRI )		
								AADD( (oHtml:ValByName( "WF.WQATU" ))	  ,TRANSFORM( SB2->B2_QATU,PesqPict("SB2","B2_QATU") ) )		
								AADD( (oHtml:ValByName( "WF.WEMIN" ))	  ,RetFldProd(SB1->B1_COD,"B1_EMIN") )		
								AADD( (oHtml:ValByName( "WF.WSALDOSC1" )) ,TRANSFORM( (SC1->(C1_QUANT-C1_QUJE)), PesqPict("SC1","C1_QUANT") ) )
								AADD( (oHtml:ValByName( "WF.WUM" ))	      ,SC1->C1_UM    )
								AADD( (oHtml:ValByName( "WF.WLOCAL" ))    ,SC1->C1_LOCAL )
								AADD( (oHtml:ValByName( "WF.WQE" ))	   	  ,TRANSFORM( SB1->B1_QE,PesqPict("SB1","B1_QE") )       )
								AADD( (oHtml:ValByName( "WF.WUPRC" ))	  ,TRANSFORM( SB1->B1_UPRC,PesqPict("SB1","B1_UPRC") )   )
								AADD( (oHtml:ValByName( "WF.WLEADTIME" )) ,Strzero(CalcPrazo(SC1->C1_PRODUTO,SC1->C1_QUANT),4)   )
								AADD( (oHtml:ValByName( "WF.WDTNECESS" )) ,Dtoc(If(Empty(SC1->C1_DATPRF),SC1->C1_EMISSAO,SC1->C1_DATPRF)) )
								AADD( (oHtml:ValByName( "WF.WDTFORCOMP" )),Dtoc(SomaPrazo(If(Empty(SC1->C1_DATPRF),SC1->C1_EMISSAO,SC1->C1_DATPRF), -CalcPrazo(SC1->C1_PRODUTO,SC1->C1_QUANT))) )		

							EndIf 
						EndIf 
					EndIf 
					//WFSalvaID('SC1','C1_XCSWFID',oProcess:fProcessID)
					(cAliasTmp)->(dbSkip())
				Enddo

				RestArea(aAreaTmp)


				//--------------------------------------------------------------+
				// Observacao                       						    |
				//--------------------------------------------------------------+
				If oHtml:ExistField(1, "WOBS")
					oHtml:ValByName("WOBS",  ""	)
				EndIf

				//--------------------------------------------------------------+
				// Chave de posicionamento                    				    |
				//--------------------------------------------------------------+
				If oHtml:ExistField(1, "WCHAVE")
					oHtml:ValByName("WCHAVE",  xFilial("DBM") + cSCNum + cCCAtu + cUsAprov	)
				EndIf


				oProcess:ClientName( Subs(cUsuario,7,15))
				oProcess:cTo := cPasta  // Destinatario do Email.

				cMailID := oProcess:Start()            

				CONOUT("Rastreando:"+oProcess:fProcCode)



				//--------------------------------------------------------------+
				//   Template do email                      				    |
				//--------------------------------------------------------------+
				oProcess:NewTask(cSubject, "\WORKFLOW\SOLICITACAO_COMPRAS\WFLINK.HTM" )  

				//--------------------------------------------------------------+
				// ASSUNTO DO E-MAIL, REFERENTE AO PROCESSO                     |
				//--------------------------------------------------------------+ 
				oProcess:cSubject := cSubject

				//--------------------------------------------------------------+
				//  Endereço eletrônico do destinatário.                        |
				//--------------------------------------------------------------+
				oProcess:cTo := UsrRetMail( cUsAprov )	 
				oProcess:ohtml:ValByName("LOGOEMP"  ,cLogoSrc)
				oProcess:ohtml:ValByName("NOMEEMP"  ,FWEmpName(cEmpAnt))
				oProcess:ohtml:ValByName("WCONTATO" , Capital(AllTrim(UsrFullName(cUsAprov))))
				oProcess:ohtml:ValByName("WNUM"     , SC1->C1_NUM )


				IF !WFGetMV( "MV_WFWEBEX", .F. )
					oProcess:ohtml:ValByName("proc_link"    ,"http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080"     )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
					oProcess:ohtml:ValByName("link_int"     ,"http://" + ALLTRIM(WFGetMV( "MV_XWFINTE", "localhost:8080"     )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
				Else
					oProcess:ohtml:ValByName("proc_link","http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080" )) +"/w_wfhttpret.apw?ProcID=" + cPasta + "/" + cMailID + ".htm")
				Endif

				oProcess:Start()	
			EndIf 
		EndDo

		StartJob( "WFLauncher", GetEnvServer(), .F., { "WFSndMsgAll", { cEmpAnt, cFilAnt } } )
	EndIf


	(cAliasTmp)->(DbCloseArea())

	RestArea( aAreaCTT )
	RestArea( aAreaE4  )
	RestArea( aAreaA2 )
	RestArea( aAreaAk )
	RestArea( aAreaAI )
	RestArea( aArea )

Return



/*/{Protheus.doc} SSCTimeOut
//TODO Timeout
@author Marcelo Evangelista
@since 23/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function SSCTimeOut( oProcess )
	ConOut("Funcao de TIMEOUT executada")
	oProcess:Finish()  //Finalizo o Processo
Return 



/*/{Protheus.doc} SSCRetorno
//TODO Executa o retorno do workflow de aprovacao da solicitacao de compras.
@author Marcelo Evangelista
@since 26/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function SSCRetorno(oProcess)

	Local cAprov    := ""
	Local cWChave   := ""
	Local cWObs     := ""
	Local cC1Item   := ""
	Local cPara     := ""
	Local cEmailCc  := ""
	Local cHtmEnv   := ""
	Local cTitulo   := ""
	Local cMsgTitul := ""
	Local cMensagem := ""
	Local cAliasTmp := GetNextAlias()
	Local nTamChv   := ""
	Local lError    := .F.
	Local lExectou  := .F.
	Local oModel    := nil
	Private lMsHelpAuto := .T.
	PRIVATE lMsErroAuto := .F.


	WFConout( "Iniciando Retorno" ,,,,.T.,"WF_SC-SSCRetorno" )	

	dbSelectArea('SC1')
	dbSetOrder(1)

	//--------------------------------------------------------------+
	// Verifica a existencia das referencias no html                |
	//--------------------------------------------------------------+
	If oProcess:oHtml:ExistField(2, "WAPROVA") .And. oProcess:oHtml:ExistField(2, "WCHAVE")


		cWChave :=  oProcess:oHtml:RetByName('WCHAVE')
		cAprov  :=  oProcess:oHtml:RetByName('WAPROVA')
		cWObs   :=  oProcess:oHtml:RetByName('WOBS')


		BeginSql Alias cAliasTmp

			SELECT 
			SC1.C1_NUM,
			SCR.CR_USER,
			SC1.R_E_C_N_O_  AS RECNOC1,
			SCR.R_E_C_N_O_  AS RECNOCR,
			DBM.R_E_C_N_O_  AS RECNODBM
			FROM %Table:SCR%  SCR
			INNER JOIN %Table:DBM% DBM ON DBM.DBM_FILIAL = SCR.CR_FILIAL
			AND DBM.DBM_NUM    = SCR.CR_NUM
			AND DBM.DBM_TIPO   = SCR.CR_TIPO
			AND DBM.DBM_GRUPO  = SCR.CR_GRUPO
			AND DBM.DBM_ITGRP  = SCR.CR_ITGRP
			AND DBM.DBM_USAPRO = SCR.CR_APROV
			AND DBM.DBM_USAPOR = SCR.CR_APRORI
			AND DBM.%NOTDEL% 
			INNER JOIN %Table:SC1% SC1 ON C1_FILIAL = DBM_FILIAL
			AND C1_NUM = DBM_NUM
			AND C1_ITEM = DBM_ITEM
			AND SC1.%NOTDEL% 
			WHERE SC1.C1_FILIAL+SC1.C1_NUM+SC1.C1_CC+SCR.CR_USER  = %Exp:cWChave%
			AND SCR.CR_TIPO = 'SC'
			AND SCR.%NOTDEL%
			ORDER BY SC1.C1_FILIAL,SC1.C1_CC,DBM.DBM_USER,DBM.DBM_ITEM

		EndSql

		memowrite("\Data\W02MretQ1.SQL",GetLastQuery()[2])

		If 	(cAliasTmp)->(!EOF())

			DbSelectArea("DBM")
			DBM->(DbSetOrder(1))

			DbSelectArea("SCR")
			SCR->(DbSetOrder(1))

			//--------------------------------------------------------------+
			// conteudo do email para os aprovadores                        |
			//--------------------------------------------------------------+
			cTitulo   := "Solicitação de Compras Nº " + (cAliasTmp)->(C1_NUM)
			cMsgTitul := "Aprovador " + Capital(AllTrim(UsrFullName((cAliasTmp)->(CR_USER)))) 
			cMensagem := "<table style='width:100%'>"
			cMensagem += "<tr>"
			cMensagem += "<th align=center>" + RetTitle("C1_FILIAL") + "</th>"
			cMensagem += "<th align=center>" + RetTitle("C1_NUM")    + "</th>"
			cMensagem += "<th align=center>" + RetTitle("C1_ITEM")   + "</th>"
			cMensagem += "<th align=center>" + RetTitle("C1_CC")     + "</th>"
			cMensagem += "<th align=center>Status</td>"
			cMensagem += "</tr>"


			While ( (cAliasTmp)->(!Eof()) )

				SCR->(DbGoTo((cAliasTmp)->(RECNOCR)))
				DBM->(DbGoTo((cAliasTmp)->(RECNODBM)))
				SC1->(DbGoTo((cAliasTmp)->(RECNOC1)))

				if ! lExectou
					BEGIN TRANSACTION

						If cAprov == 'L'
							//--------------------------------------------------------------+
							// Liberar                   							        |
							//--------------------------------------------------------------+
							RecLock("SCR",.F.)
							SCR->CR_DATALIB := dDataBase
							SCR->(MsUnlock()) 
							If (lError := ! A097ProcLib(SCR->(Recno()),2,,,,,dDataBase))
								WFConout( "Falha aprovaçao da solicitacao de compras FILIAL+NUM+CC+USER " + AllTrim(cWChave) ,,,,.T.,"WF_SC-SSCRetorno" )
							Else
								WFConout( "Executado aprovaçao da solicitaçao de compras FILIAL+NUM+CC+USER " + AllTrim(cWChave) ,,,,.T.,"WF_SC-SSCRetorno" )
							EndIf
						Else // cAprov = 'R'

							//--------------------------------------------------------------+
							// Rejeitar                   							        |
							//--------------------------------------------------------------+
							oModel := FWLoadModel('MATA094')
							oModel:SetOperation( MODEL_OPERATION_UPDATE )
							oModel:SetActivate( { |oModel| .T. } )
							if oModel:Activate()
								oModel:SetValue( "FieldSCR", "CR_OBS", SubStr(cWObs,1,TamSx3("CR_OBS")[1]))
								BEGIN TRANSACTION

									If (lError := ! MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,,SCR->CR_APROV,,SCR->CR_GRUPO,,,,dDataBase,FwFldGet("CR_OBS")}, dDataBase ,7,,,,,,,))
										WFConout( "Falha Rejeição da solicitacao de compras FILIAL+NUM+CC+USER " + AllTrim(cWChave) ,,,,.T.,"WF_SC-SSCRetorno" )
									Else
										WFConout( "Executado Rejeição da solicitaçao de compras FILIAL+NUM+CC+USER " + AllTrim(cWChave) ,,,,.T.,"WF_SC-SSCRetorno" )
									EndIf

								End TRANSACTION
								oModel:DeActivate()
							EndIf
						EndIf

					END TRANSACTION
					lExectou := .T.
				EndIf 
				//--------------------------------------------------------------+
				// Detalhes por item  					                        |
				//--------------------------------------------------------------+
				cMensagem += "<tr>"
				cMensagem += "<td align=center>" + cFilAnt + " - " + FWFilialName() + "</td>"
				cMensagem += "<td align=center>" + DBM->DBM_NUM  + "</td>"
				cMensagem += "<td align=center>" + DBM->DBM_ITEM + "</td>"
				cMensagem += "<td align=center>" + SC1->C1_CC	 + "</td>"
				cMensagem += "<td align=center>" + W02MSTAT(cAprov,lError) + "</td>"
				cMensagem += "</tr>"

				(cAliasTmp)->(dbSkip())
			EndDo
		EndIf

		cMensagem += "</table>"
		cMensagem += "<hr>"

		If cAprov == 'R'
			cMensagem += "<table style='width:100%'>"
			cMensagem += "<tr>"
			cMensagem += "<th align=center>Observações</td>"
			cMensagem += "</tr>"
			cMensagem += "<tr>"
			cMensagem += "<td align=center>" + cWObs + "</td>"
			cMensagem += "</tr>"
			cMensagem += "</table>"
		EndIf


		(cAliasTmp)->(dbCloseArea())

		nTamChv :=  (Tamsx3("C1_FILIAL")[1]+Tamsx3("C1_NUM")[1]+Tamsx3("C1_CC")[1])	

		BeginSql Alias cAliasTmp

			SELECT 
			SCR.CR_USER
			FROM %Table:SCR%  SCR
			INNER JOIN %Table:DBM% DBM ON DBM.DBM_FILIAL = SCR.CR_FILIAL
			AND DBM.DBM_NUM    = SCR.CR_NUM
			AND DBM.DBM_TIPO   = SCR.CR_TIPO
			AND DBM.DBM_GRUPO  = SCR.CR_GRUPO
			AND DBM.DBM_ITGRP  = SCR.CR_ITGRP
			AND DBM.DBM_USAPRO = SCR.CR_APROV
			AND DBM.DBM_USAPOR = SCR.CR_APRORI
			AND DBM.%NOTDEL% 
			INNER JOIN %Table:SC1% SC1 ON C1_FILIAL = DBM_FILIAL
			AND C1_NUM = DBM_NUM
			AND C1_ITEM = DBM_ITEM
			AND SC1.%NOTDEL% 
			WHERE SC1.C1_FILIAL+SC1.C1_NUM+SC1.C1_CC  = %Exp:SubStr(cWChave,1,nTamChv)%
			AND SCR.CR_USER <> %Exp:SubStr(cWChave,(nTamChv+1),Len(cWChave))%
			AND SCR.CR_TIPO = 'SC'
			AND SCR.%NOTDEL%
			Group by SCR.CR_USER
		EndSql

		memowrite("\Data\W02MretQ2.SQL",GetLastQuery()[2])

		If 	(cAliasTmp)->(!EOF())
			While ( (cAliasTmp)->(!Eof()) )
				cEmailCc +=  UsrRetMail( (cAliasTmp)->(CR_USER) )+";"	
				(cAliasTmp)->(dbSkip())
			EndDo
		EndIf

		(cAliasTmp)->(dbCloseArea())

		cPara    := UsrRetMail(SubStr(cWChave,nTamChv,Len(cWChave)))
		cEmailCc += UsrRetMail(SC1->C1_USER)
		cHtmEnv  := WFHtmlTemplate(cTitulo, cMensagem, cMsgTitul ) 
		memowrite("\Data\W02Mret.htmL",cHtmEnv)
		//EnvEmail(cPara,cCopia,cConhCopia,cAssunto,cDe,cTexto,lHtml,aFile)

		U_EnvEmail(cPara,cEmailCc,/*<cConhCopia>*/,"Resultado Sc " + SC1->C1_NUM,/*De */, cHtmEnv )
	EndIf

	WFConout( "Finalizando Retorno" ,,,,.T.,"WF_SC-SSCRetorno" )	

Return



/*/{Protheus.doc} W02MSTAT
//TODO Retorna descricao da aprovaçao/rejeição
@author PROTHEUS
@since 16/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
Static Function W02MSTAT(cAprov,lError)

	Local cRetorno := ""
	If cAprov == "L"

		cRetorno := IIf (!lError,"Aprovado" ,"Falha ao aprovar.")

	else

		cRetorno := IIf (!lError,"Rejeitado","Falha ao rejeitar.")

	Endif

Return  (cRetorno)