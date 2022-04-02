#Include 'Protheus.ch'

/*/{Protheus.doc} MT150ROT

LOCALIZA��O : Function MATA150 - Fun��o da atualiza��o de cota��es. EM QUE PONTO : No inico da rotina e antes da execu��o da Mbrowse da cota��o, 
utilizado para adicionar mais op��es no aRotina.

@author Marcelo Evangelista
@since 18/08/2015
@version 1.0
/*/

User Function MT150ROT()

	If ExistBlock("COMW01M")
		AAdd( aRotina, { "Env. Email Forn."   , "EXECBLOCK('COMW01M',.T.,.T.)"   , 0 , 1 } )
	Endif

Return ( aRotina )