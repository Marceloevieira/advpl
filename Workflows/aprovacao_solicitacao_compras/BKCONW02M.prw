#include 'protheus.ch'
#include 'parmtype.ch'

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
	Local cNumSol  := PARAMIXB[1]


	DbSelectArea("SC1")
	SC1->(DbSetOrder(1))


	IF SC1->(dbSeek(XFilial("SC1")+cNumSol))  .And. SC1->C1_APROV = 'B'

		SSCINICIAR()
	ENDIF

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
Static Function SSCINICIAR(oProcess)

	Local aArea    := GetArea()
	Local aAreaAI  := SAI->(GetArea())
	Local aAreaA2  := SA2->(GetArea())
	Local aAreaE4  := SE4->(GetArea())
	Local aAreaCTT := CTT->( GetArea() )
	Local aRetUser := {} 
	Local cSCNum   := SC1->C1_NUM
	Local cC1OBS   := ""
	Local cMailID  := ""
	Local cPasta   := "solicitacao"
	Local cSubject := "Solicitação de Compra (Nº " + SC1->C1_NUM + ")"
	Local cLogoSrc := GetNewPar( "MV_XLOGOWF" , "http://dnsconsultoria.net.br/wp-content/uploads/2017/11/LOGO1.png" )
	Local oProcess := NIL 



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


	While !Eof() .and. SC1->(C1_FILIAL+C1_NUM) == xFilial("SC1") + cSCNum

		If SC1->C1_APROV == 'B'
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

					cC1OBS += AllTrim(SC1->C1_OBS) + CRLF		
				EndIf 
			EndIf 
		EndIf 
		//WFSalvaID('SC1','C1_XCSWFID',oProcess:fProcessID)
		SC1->(dbSkip())
	Enddo

	SC1->( DbGoTop())
	SC1->( DbSeek(xFilial('SC1')+cSCNum) )


	//--------------------------------------------------------------+
	// Observacao                       						    |
	//--------------------------------------------------------------+
	If oHtml:ExistField(1, "WOBS")
		oHtml:ValByName("WOBS",  cC1OBS	)
	EndIf

	//--------------------------------------------------------------+
	// Chave de posicionamento                    				    |
	//--------------------------------------------------------------+
	If oHtml:ExistField(1, "WCHAVE")
		oHtml:ValByName("WCHAVE",  SC1->(C1_FILIAL+C1_NUM)	)
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
	//	oProcess:cTo := UsrRetMail( SAK->AK_USER )	 
	oProcess:cTo := UsrRetMail( RetCodUsr() )	 

	oProcess:ohtml:ValByName("LOGOEMP"  ,cLogoSrc)
	oProcess:ohtml:ValByName("NOMEEMP"  ,FWEmpName(cEmpAnt))
	//	oProcess:ohtml:ValByName("WCONTATO", AllTrim(UsrFullName(SAK->AK_USER)))
	oProcess:ohtml:ValByName("WCONTATO" , Capital(AllTrim(UsrFullName(RetCodUsr()))))
	oProcess:ohtml:ValByName("WNUM"     , SC1->C1_NUM )


	IF !WFGetMV( "MV_WFWEBEX", .F. )
		oProcess:ohtml:ValByName("proc_link"    ,"http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080"     )) +"/messenger/emp" + cEmpAnt + "/" + cPasta + "/" + cMailID + ".htm")
	Else
		oProcess:ohtml:ValByName("proc_link","http://" + ALLTRIM(WFGetMV( "MV_WFBRWSR", "localhost:8080" )) +"/w_wfhttpret.apw?ProcID=" + cPasta + "/" + cMailID + ".htm")
	Endif

	oProcess:Start()	

	RestArea( aAreaCTT )
	RestArea( aAreaE4  )
	RestArea( aAreaA2 )
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

	Local cAprov  := ""
	Local cWChave := ""
	Local cWObs   := ""
	Local cC1Item := ""
	Local nTotIt  := 0
	Local aCabec  := {}
	Local aItens  := {}
	Local aLinha  := {}

	Private lMsHelpAuto := .T.
	PRIVATE lMsErroAuto := .F.


	//--------------------------------------------------------------+
	// Verifica a existencia das referencias no html                |
	//--------------------------------------------------------------+
	If oProcess:oHtml:ExistField(2, "WAPROVA") .And. oProcess:oHtml:ExistField(2, "WCHAVE")

		cWChave :=  oProcess:oHtml:RetByName('WCHAVE')
		cAprov  :=  oProcess:oHtml:RetByName('WAPROVA')
		cWObs   :=  oProcess:oHtml:RetByName('WOBS')
		nTotIt  :=  len(oProcess:oHtml:RetByName("WF.WITEM"))




		dbSelectArea('SC1')
		dbSetOrder(1)
		If SC1->(MsSeek(cWChave))

			AADD(aCabec ,{"C1_FILIAL" ,SC1->C1_FILIAL   ,Nil})
			AADD(aCabec ,{"C1_NUM"    ,SC1->C1_NUM 		,Nil})
			AADD(aCabec ,{"C1_SOLICIT",SC1->C1_SOLICIT	,Nil})
			AADD(aCabec ,{"C1_EMISSAO",SC1->C1_EMISSAO 	,Nil})
			aadd(aCabec ,{"C1_APROV"  ,cAprov           , Nil})

			For nX := 1 To nTotIt

				cC1Item := 	oProcess:oHtml:RetByName("WF.WITEM")[nX]

				If SC1->(MsSeek(cWChave + cC1Item))
					aLinha := {}             
					aadd(aLinha,{"C1_ITEM"	  ,SC1->C1_ITEM   , Nil })

					aadd(aItens,aLinha)        
				EndIf
			Next

			If Len(aCabec) > 0 .And. Len(aItens) > 0

				MSExecAuto({|x,y,z| mata110(x,y,z)},aCabec,aItens,7)  

				If lMsErroAuto
					WFConout( "Falha aprovaçao da solicitacao de compras FILIAL+C1_NUM " + cWChave ,,,,.T.,"WF_SC-SSCRetorno" )
				Else
					WFConout( "Executado aprovaçao da solicitaçao de compras FILIAL+C1_NUM " + cWChave ,,,,.T.,"WF_SC-SSCRetorno" )
				EndIf 
			EndIf	
		EndIf
	EndIf

Return
