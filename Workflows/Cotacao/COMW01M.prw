#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMW01M
//TODO Fonte responsavel pelo envio e retorno do workflow da cotaçao.
@author Marcelo Evangelista
@since 02/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
user function COMW01M()

	Local aArea        := GetArea()
	Local aAreaSY1     := SY1->(GetArea())
	Local aAreaSC1     := SC1->(GetArea())
	Local aAreaSC8     := SC8->(GetArea())
	Local aAreaSA2     := SA2->(GetArea())
	Local aAreaSB1     := SB1->(GetArea())
	Local aTamSXG      := TamSXG("001")
	Local aCond        := {}
	Local _cC8_NUM     := ""
	Local _cC8_FORNECE := ""
	Local _cC8_LOJA    := ""
	Local _cEmlFor     := ""
	Local _cNumCot     := SC8->C8_NUM
	Local cFornece     := ""
	Local _lAtvWf      := GetNewPar( "MV_XATVWF" , .F. )
	Local cSolicit     := ""
	Local cCodUsr      := "" 
	Local cNomeComp    := ""
	Local cFoneComp    := ""
	Local cMailComp    := ""
	Local cLogoSrc     := GetNewPar( "MV_XLOGOWF" , "https://i.imgur.com/JiAa84l.png" ) 	
	Local cMailID      := ""
	Local cPasta       := "cotacao" 
	Local cSubject     := ""
	Local oProcess     := NIL
	Local bFornece     := {|| .T. }
	Local lMATA150     :=  IsInCallStack("MATA150")


	If ( MsgYesNo( "Deseja enviar a cotação para o fornecedor?" , "Cotação" ) )      		

		If Type( "PARAMIXB[1]" ) <> "U"
			_cNumCot := ParamIXB[1]
		EndIf
		//--------------------------------------------------------------+
		// Reenviar somente para a cotaçao posicionada                  |
		//--------------------------------------------------------------+
		If lMATA150
			cFornece := SC8->(C8_FORNECE+C8_LOJA)
			bFornece := {|| cFornece == SC8->(C8_FORNECE+C8_LOJA) } 
		EndIf

		DBSelectArea("SB1")
		SB1->(DBSetOrder(1))

		DBSelectArea("SC8")
		SC8->(DBSetOrder(1))

		If  SC8->( DBSeek(xFilial("SC8")+_cNumCot + cFornece ))

			//--------------------------------------------------------------+
			// Busca as condicoes de pagamento                              |
			//--------------------------------------------------------------+
			DbSelecTArea("SE4")
			SE4->(DbSetOrder(1))
			SE4->(DBGoTop())
			While !SE4->(EOF()) .and. SE4->E4_FILIAL == xFilial("SE4")
				If SE4->(FieldPos("E4_XEXBCOT") > 0 .And. E4_XEXBCOT == "S" ) .And. SE4->E4_MSBLQL <> '1'	
					AADD( aCond, SE4->E4_CODIGO + " - " + SE4->E4_DESCRI )
				EndIf
				SE4->(DBSkip())
			Enddo


			While ! SC8->(Eof()) .and. xFilial("SC8")+_cNumCot == SC8->(C8_FILIAL+C8_NUM) .And. eval(bFornece)

				_cC8_NUM     := SC8->C8_NUM
				_cC8_FORNECE := SC8->C8_FORNECE
				_cC8_LOJA    := SC8->C8_LOJA

				DBSelectArea('SA2')  
				DBSetOrder(1)
				DBSeek( xFilial('SA2') + _cC8_FORNECE + _cC8_LOJA )

				_cEmlFor := SA2->A2_XMAILCO

				if ! Empty(Alltrim(_cEmlFor)) 

					oProcess := TWFProcess():New( "COTCOM", "Cotação de Preços" )
					oProcess:NewTask( "Fluxo de Compras", "\WORKFLOW\COTACAO\COTACAO.HTM" )
					oHtml    := oProcess:oHTML


					//--------------------------------------------------------------+
					// Logo   	-MV_WFIMAGE  .F.			                        |
					//--------------------------------------------------------------+	
					oHtml:ValByName( "LOGOEMP" , cLogoSrc    )
					oHtml:ValByName( "NOMEEMP" , FWEmpName(cEmpAnt) )



					//--------------------------------------------------------------+
					// Fornecedor							                        |
					//--------------------------------------------------------------+				
					DBSelectArea('SA2')  
					DBSetOrder(1)
					DBSeek( xFilial('SA2') + _cC8_FORNECE + _cC8_LOJA )


					oHtml:ValByName( "WFFORNECE" , (SubStr(SA2->A2_NOME,1,If(aTamSXG[1] != aTamSXG[3],25,40))+" ("+SA2->A2_COD+" - "+SA2->A2_LOJA+")" ))
					oHtml:ValByName( "WFENDFORN" , SA2->A2_END )
					oHtml:ValByName( "WFBAIRROFR", (AllTrim(SA2->A2_BAIRRO) + "  " + Alltrim(SA2->A2_MUN) + " - " + AllTrim(SA2->A2_EST))    )
					oHtml:ValByName( "WFFONEFOR" , (SA2->A2_DDD+" " + SA2->A2_TEL)    )
					oHtml:ValByName( "WFFAXFORN" , (SA2->A2_DDD+" " + SA2->A2_FAX)    )



					//--------------------------------------------------------------+
					// DADOS DA CABEÇALHO COTACAO			                        |
					//--------------------------------------------------------------+				
					oHtml:ValByName( "WFTNUMCOT" , SC8->C8_NUM     )
					oHtml:ValByName( "WFVENCCOT" , SC8->C8_VALIDA  )
					oHtml:ValByName( "WFVENCCOT" , SC8->C8_VALIDA  )
					oHtml:ValByName( "CONDPAG"   , aCond    )


					//--------------------------------------------------------------+
					// Controle de retorno                       				    |
					//--------------------------------------------------------------+
					oHtml:ValByName( "Wchave"   , SC8->(C8_NUM+C8_FORNECE+C8_LOJA)  )

					//--------------------------------------------------------------+
					// DADOS DA EMPRESA                        						|
					//--------------------------------------------------------------+
					oHtml:ValByName( "WFNOMECOM" , SM0->M0_NOMECOM   )
					oHtml:ValByName( "WFENDEMP"  , If(Empty(SM0->M0_ENDENT),SM0->M0_ENDCOB,SM0->M0_ENDENT)    )	       
					oHtml:ValByName( "WFBAIREMP" , If(Empty(SM0->M0_CIDENT+SM0->M0_ESTENT), SM0->M0_CIDCOB + " " + SM0->M0_ESTCOB,  SM0->M0_CIDENT + " " + SM0->M0_ESTENT)   )
					oHtml:ValByName( "WFFONEEMP" , SM0->M0_TEL    )
					oHtml:ValByName( "WFFAXEMP"  , SM0->M0_FAX 	 )
					oHtml:ValByName( "WFEMAILEMP", ""    )	       




					//--------------------------------------------------------------+
					//  Dados Itens cotaçao                       				    |
					//--------------------------------------------------------------+

					While ! SC8->(Eof()) .and. SC8->C8_FILIAL = xFilial("SC8") ;
					.and. SC8->C8_NUM     = _cC8_NUM ;
					.and. SC8->C8_FORNECE = _cC8_FORNECE ;
					.and. SC8->C8_LOJA    = _cC8_LOJA 


						If SB1->(MsSeek(xFilial("SB1") + SC8->C8_PRODUTO )  )

							AADD( (oHtml:ValByName( "IT.ITEM"    )), SC8->C8_ITEM    )
							AADD( (oHtml:ValByName( "IT.CODIGO"  )), SC8->C8_PRODUTO )
							AADD( (oHtml:ValByName( "IT.DESCRI"  )), ALLTRIM(SB1->B1_DESC)    ) // SC8->C8_DESCRI  )
							AADD( (oHtml:ValByName( "IT.QUANT"   )), ALLTRIM(TRANSFORM( SC8->C8_QUANT,PesqPict("SC8","C8_QUANT") ) ))
							AADD( (oHtml:ValByName( "IT.UN"      )), ALLTRIM(SC8->C8_UM)      )
							AADD( (oHtml:ValByName( "IT.VLRUNI"  )), ALLTRIM(TRANSFORM( 0.00,PesqPict("SC8","C8_PRECO")))   )
							AADD( (oHtml:ValByName( "IT.VLRTOT"  )), ALLTRIM(TRANSFORM( 0.00,PesqPict("SC8","C8_TOTAL") ) ) )
							AADD( (oHtml:ValByName( "IT.DESCON"  )), ALLTRIM(TRANSFORM( 0.00,PesqPict("SC8","C8_VLDESC") ) ) )
							AADD( (oHtml:ValByName( "IT.VLRICMST")), ALLTRIM(TRANSFORM( 0.00,PesqPict("SC8","C8_VALSOL") ) ) )
							AADD( (oHtml:ValByName( "IT.VLRIPI"))  , ALLTRIM(TRANSFORM( 0.00,PesqPict("SC8","C8_VALIPI") ) ) )
							AADD( (oHtml:ValByName( "IT.PRZENTR" )), " "    )
							aAdd( (oHtml:ValByName( "IT.NECESSI" )), Dtoc(SC8->C8_DATPRF)          )
							aAdd( (oHtml:ValByName( "IT.MARCAPRD")), " "      )
							aAdd( (oHtml:ValByName( "IT.OBS"))	   , AllTrim(SC8->C8_OBS)      )
							aAdd( (oHtml:ValByName( "IT.OBSCOFOR")), " "      )
						EndIf	


						SC8->(DBSkip())
					enddo



					//--------------------------------------------------------------+
					// Complementos                        						    |
					//--------------------------------------------------------------+
					oHtml:ValByName( "WFENDENTR" , If( Empty(SM0->M0_ENDENT), " O mesmo ", SM0->M0_ENDENT)    )
					oHtml:ValByName( "WFENDCOB"  , If(Empty(SM0->M0_ENDCOB),Iif(Empty(SM0->M0_ENDENT),"O mesmo",SM0->M0_ENDENT),SM0->M0_ENDCOB)    )
					oHtml:ValByName( "FRETE"     , CarregaTipoFrete()   )
					oHtml:ValByName( "VALFRETE"  , "0,00"   )
					oHtml:ValByName( "TOTICMST"  , "0,00"   )
					oHtml:ValByName( "TOTIPI"    , "0,00"   )
					

					//--------------------------------------------------------------+
					// Dados Do Comprador 					                        |
					//--------------------------------------------------------------+
					cSolicit := Posicione( "SC1" , 5 , xFilial( "SC1" ) + _cC8_NUM , "C1_SOLICIT"  )

					//Busca o código do usuário através do nome
					PswOrder( 2 )
					If PswSeek( cSolicit , .T. )
						cCodUsr := AllTrim( PswID() ) 
					EndIf

					cNomeComp := AllTrim( Posicione( "SY1" , 3 , xFilial( "SY1" ) + cCodUsr , "Y1_NOME" ) )
					cFoneComp := AllTrim( Posicione( "SY1" , 3 , xFilial( "SY1" ) + cCodUsr , "Y1_TEL" ) )
					cMailComp := AllTrim( Posicione( "SY1" , 3 , xFilial( "SY1" ) + cCodUsr , "Y1_EMAIL" ))


					cSubject := EncodeUTF8("Envio Cotacao de Precos " + _cC8_NUM, "iso8859-1")
					oProcess:cSubject := cSubject
					oProcess:cTo      := cPasta
					oProcess:bReturn  := "U_W1881503(1)"
					cMailID := oProcess:Start() 

					oProcess:NewTask( cSubject, "\WORKFLOW\COTACAO\WFLINK.HTM" )
					oProcess:cTo	:= _cEmlFor
					oProcess:cBCC	:= GetNewPar( "MV_XCCWF" , "compras@dual.ind.br" )


					//oProcess:ohtml:ValByName("referente","cotação de preços de seus produtos.")
					oProcess:ohtml:ValByName("LOGOEMP",cLogoSrc)
					oProcess:ohtml:ValByName("NOMEEMP",FWFilRazSocial())
					oProcess:ohtml:ValByName("comprador",cNomeComp)
					oProcess:ohtml:ValByName("fonecomp",cFoneComp)
					oProcess:ohtml:ValByName("mailcomp",cMailComp)

					IF !WFGetMV( "MV_WFWEBEX", .F. )
						oProcess:ohtml:ValByName("proc_link"    ,"http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080" )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
					Else
						oProcess:ohtml:ValByName("proc_link"    ,"http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080" )) +"/w_wfhttpret.apw?ProcID=" + cPasta + "/" + cMailID + ".htm")
					Endif

					oProcess:Start() 
					MessageBox("Email enviado ao fornecedor " + _cEmlFor + ". Cotação : " + _cC8_NUM , "Envio de Email", 0)


				Else

					SC8->(DBSkip())
				Endif
			Enddo
		EndIf

		If !lMATA150
			StartJob( "WFLauncher", GetEnvServer(), .F., { "WFSndMsgAll", { cEmpAnt, cFilAnt } } )
		EndIf
	EndIf

	RestArea(aAreaSB1)
	RestArea(aAreaSA2)
	RestArea(aAreaSY1)
	RestArea(aAreaSC1)
	RestArea(aAreaSC8)
	RestArea(aArea)

Return

/*/{Protheus.doc} W1881503

Programa executado durante retorno de cotacoes preenchidas por fornecedores

@author Otaviano Mattos
@since 15/08/2015
@version 1.0
/*/

User Function W1881503( AOpcao , oProcess ) 

	Local nX       := 0
	Local nTotItem := len(oProcess:oHtml:RetByName("IT.ITEM")) 
	Local cChaveC8 := oProcess:oHtml:RetByName("Wchave" )
	Local cC8Item  := ""
	Local cAssunto := ""
	Local cMensagem:= ""
	Local cPasta   := WFGetMV( "MV_WFMLBOX", "" )

	DBSelectArea("SC8")
	DBSetOrder(1)
	If SC8->(DBSeek( xFilial("SC8") + cChaveC8 ))

		cAssunto  := "Retorno Cotacao de Precos " + SC8->C8_NUM
		cMensagem := "Email respondido pelo Fornecedor: ("+ SC8->(C8_FORNECE+"-"+C8_LOJA) +") " + Posicione("SA2",1,xFilial("SA2") + SC8->(C8_FORNECE+C8_LOJA),"A2_NOME") 	

		For nX := 1 to  nTotItem

			cC8Item := oProcess:oHtml:RetByName("IT.ITEM")[nX]    

			If SC8->(DBSeek( xFilial("SC8") + cChaveC8 + cC8Item ))

				RecLock("SC8",.f.)

				SC8->C8_PRECO   := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.VLRUNI")[nX],".",""),",","."))
				SC8->C8_TOTAL   := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.VLRTOT")[nX],".",""),",","."))              
				SC8->C8_TPFRETE := Substr(oProcess:oHtml:RetByName("FRETE"),1,1) 
				SC8->C8_VALFRE  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("VALFRETE"),".",""),",",".")) / nTotItem
				SC8->C8_PRAZO   := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.PRZENTR")[nX],".",""),",","."))
				SC8->C8_XMARCA  := oProcess:oHtml:RetByName("IT.MARCAPRD")[nX]
				if !Empty(Substr(oProcess:oHtml:RetByName("CONDPAG"),1,3))
					SC8->C8_COND    := Substr(oProcess:oHtml:RetByName("CONDPAG"),1,3)
				EndIf
				SC8->C8_VLDESC  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.DESCON")[nX],".",""),",","."))
				SC8->C8_VALSOL  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.VLRICMST")[nX],".",""),",","."))
				SC8->C8_VALIPI  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("IT.VLRIPI")[nX],".",""),",","."))
				SC8->C8_XOBSFOR := AllTrim(oProcess:oHtml:RetByName("IT.OBSCOFOR")[nX])	

				MsUnlock()
			EndIf
		Next

		RastreiaWF("00001"+'.'+oProcess:fTaskID,"000001",'1004',cMensagem)

		DbSelectArea("WF7")
		WF7->(DbSetOrder(1))
		If WF7->(DbSeek(xFilial("WF7") + cPasta))
			GPEMail(cAssunto,cMensagem,WF7->WF7_ENDERE)	
		EndIf
	Endif


Return