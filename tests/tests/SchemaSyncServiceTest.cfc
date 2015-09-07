component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
	}

	// executes after all suites+specs in the run() method
	function afterAll(){}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "syncSchema", function(){
			it( "should do magic", function(){
				var syncService = _getSyncService();
			} );
		} );
	}

/*********************************** PRIVATE HELPERS ***********************************/
	private function _getSyncService() {
		variables.mockdsn               = "testdsn";
		variables.mockVersioningService = getMockBox().createEmptyMock( "presidedataobjects.db.schema.SchemaVersioningService" );
		variables.mockDbInfoService     = getMockBox().createEmptyMock( "presidedataobjects.db.DbInfoService" );
		variables.mockSqlAdapter        = getMockBox().createStub();
		variables.mockAdapterFactory    = getMockBox().createEmptyMock( "presidedataobjects.db.adapter.AdapterFactory" );
		variables.mockSqlRunner         = getMockBox().createEmptyMock( "presidedataobjects.db.SqlRunner" );
		variables.mockSchemaGenerator   = getMockBox().createStub();
		variables.mockTableFieldsHelper = getMockBox().createEmptyMock( "presidedataobjects.db.helpers.ObjectTableFieldsHelper" );
		variables.mockAdapterFactory.$( "getAdapter" ).$args( dsn=mockDsn ).$results( mockSqlAdapter );

		return getMockBox().createMock(
			object = new presidedataobjects.db.schema.SchemaSyncService(
				  dsn                     = mockdsn
				, dbInfoService           = mockDbInfoService
				, adapterFactory          = mockAdapterFactory
				, sqlRunner               = mockSqlRunner
				, schemaGenerator         = mockSchemaGenerator
				, schemaVersioningService = mockVersioningService
				, objectTableFieldsHelper = mockTableFieldsHelper
			)
		);
	}
}
