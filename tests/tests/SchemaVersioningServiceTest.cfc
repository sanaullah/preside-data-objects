component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		variables.versionTableName = "_preside_generated_entity_versions";
		variables.mockDsn          = "mockdsn";
	}

	// executes after all suites+specs in the run() method
	function afterAll(){}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "versioningTableExists", function(){
			it( "should return false when the database table for the setup datasource does not exist", function(){
				schemaVersioningService = _getVersioningService();

				mockDbInfoService.$( "getTableInfo" ).$args( tableName=versionTableName, dsn=mockDsn ).$results( QueryNew('') );

				expect( schemaVersioningService.versioningTableExists() ).toBe( false );
			} );

			it( "should return true when the database table exists", function(){
				schemaVersioningService = _getVersioningService();

				mockDbInfoService.$( "getTableInfo" ).$args( tableName=versionTableName, dsn=mockDsn ).$results( QueryNew('tablename', 'varchar', [[versionTableName]] ) );

				expect( schemaVersioningService.versioningTableExists() ).toBe( true );
			} );
		} );

		describe( "getCreateVersioningTableSql", function(){
			it( "should use the sql adapter for the datasource to formulate a create table sql definition and index for the versioning table", function(){
				var schemaVersioningService = _getVersioningService();
				var columns = [
					  { columnName="entity_type",        dbType="varchar"  , maxLength  = 10  , nullable   = false }
					, { columnName="entity_name",        dbType="varchar"  , maxLength  = 200 , nullable   = false }
					, { columnName="parent_entity_name", dbType="varchar"  , maxLength  = 200 , nullable   = true  }
					, { columnName="version_hash",       dbType="varchar"  , maxLength  = 32  , nullable   = false }
					, { columnName="date_modified",      dbType="timestamp"                   , nullable   = false }
				];
				var mockColumnDefSql = "";
				var mockTableDefSql = "this is dummy table create sql" & CreateUUId();
				var mockIndexDefSql = "this is the index sql" & CreateUUId();

				for( var i=1; i<=columns.len(); i++ ){
					var mockSql = "column#i#";
					mockSqlAdapter.$( "getColumnDefinitionSql" ).$args( argumentCollection=columns[i] ).$results( mockSql );
					mockColumnDefSql = ListAppend( mockColumnDefSql, mockSql );
				}

				mockSqlAdapter.$( "getTableDefinitionSql" ).$args( tableName=versionTableName, columnSql=mockColumnDefSql ).$results( mockTableDefSql );
				mockSqlAdapter.$( "getIndexSql" ).$args(
					  indexName = "ux_preside_generated_entity_versions"
					, tableName = versionTableName
					, fieldlist = "entity_type,parent_entity_name,entity_name"
					, unique    = true )
				.$results( mockIndexDefSql );

				expect( schemaVersioningService.getCreateVersioningTableSql() ).toBe( [ mockTableDefSql, mockIndexDefSql ] );

			} );
		} );

		describe( "createVersioningTable", function(){
			it( "should do nothing when the table already exists", function(){
				var schemaVersioningService = _getVersioningService();

				schemaVersioningService.$( "versioningTableExists", true );
				mockSqlRunner.$( "runSql" );

				schemaVersioningService.createVersioningTable();

				var sqlRunLog = mockSqlRunner.$callLog().runSql;
				expect( sqlRunLog.len() ).toBe( 0 );
			} );

			it( "should run sql to create version table when the table does not already exist", function(){
				var schemaVersioningService = _getVersioningService();
				var dummySql                = [ "Dummy SQL here: #CreateUUId()#", "another sql statement #CreateUUId()#" ];

				schemaVersioningService.$( "versioningTableExists", false );
				schemaVersioningService.$( "getCreateVersioningTableSql", dummySql );
				mockSqlRunner.$( "runSql", NullValue() );

				schemaVersioningService.createVersioningTable();

				var sqlRunLog = mockSqlRunner.$callLog().runSql;
				expect( sqlRunLog.len() ).toBe( dummySql.len() );
				for( var i=1; i<=sqlRunLog.len(); i++ ) {
					expect( sqlRunLog[i] ).toBe( { sql=dummySql[i], dsn=mockDsn } );
				}
			} );
		} );
	}

/*********************************** PRIVATE HELPERS ***********************************/
	private function _getVersioningService() {
		variables.mockDbInfoService  = getMockBox().createEmptyMock( "presidedataobjects.db.DbInfoService" );
		variables.mockSqlAdapter     = getMockBox().createStub();
		variables.mockAdapterFactory = getMockBox().createEmptyMock( "presidedataobjects.db.adapter.AdapterFactory" );
		variables.mockSqlRunner      = getMockBox().createEmptyMock( "presidedataobjects.db.SqlRunner" );

		variables.mockAdapterFactory.$( "getAdapter" ).$args( dsn=mockDsn ).$results( mockSqlAdapter );

		return getMockBox().createMock(
			object = new presidedataobjects.db.schema.SchemaVersioningService(
				  dsn              = mockdsn
				, dbInfoService    = mockDbInfoService
				, versionTableName = versionTableName
				, adapterFactory   = mockAdapterFactory
				, sqlRunner        = mockSqlRunner
			)
		);
	}
}
