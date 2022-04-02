#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMA01M
//TODO modelo criado para compatiblizar rejeiçao via rotina automatica
@author PROTHEUS
@since 16/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function COMA01M()

	Local oBrowse

	//-> Instanciamento da Classe de Browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SCR")
	oBrowse:DisableDetails()
	oBrowse:Activate()

Return NIL



/*/{Protheus.doc} MenuDef
//TODO função que retorna os menus da rotina
@author PROTHEUS
@since 16/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
Static Function MenuDef()
Return(FWMVCMenu("COMA01M"))



/*/{Protheus.doc} ModelDef
//TODO modelo
@author PROTHEUS
@since 16/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
Static Function ModelDef()

	Local oModel := MPFormModel():New("COMA01MX")
	Local oStruSCR:= FWFormStruct(1,'SCR')

	oModel:addFields('FIELDSCR',,oStruSCR)
	
	oModel:SetPrimaryKey(StrTokArr(AllTrim(SCR->(OrdKey(2))),"+"))	
	
Return oModel



/*/{Protheus.doc} ViewDef
//TODO view 
@author PROTHEUS
@since 16/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
Static Function ViewDef()

	Local oModel  := FWLoadModel("COMA01M")
	Local oView   := FWFormView():New()
	Local oStruSCR:= FWFormStruct(2,'SCR')


	oView:SetModel(oModel)
	oView:addField("SCRFIELD",oStruSCR,"FIELDSCR")

	oView:CreateHorizontalBox( "BOX1", 100)
	//	_oView:CreateHorizontalBox( "BOX2", 90)

	//-- Seta componente ao container.
	oView:SetOwnerView("SCRFIELD" ,"BOX1")
	//	_oView:SetOwnerView("VIEW_GRID"  ,"BOX2")

	//-- Força o fechamento da tela ao salvar o model.
	oView:SetCloseOnOk({|| .T. })

Return oView