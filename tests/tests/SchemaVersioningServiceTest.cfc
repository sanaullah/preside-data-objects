component extends="testbox.system.BaseSpec"{
	processingdirective preserveCase=true;

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

		describe( "versionExists", function(){
			it( "should return false if a db record does not exist for the given entity type, entity name and parent entity name", function(){
				var schemaVersioningService = _getVersioningService();
				var filterSql               = "entity_type = :entity_type and entity_name = :entity_name and parent_entity_name = :parent_entity_name";
				var dummySql                = "some dummy sql" & CreateUUId();
				var entityType              = "entityType" & CreateUUId();
				var entityName              = "entityName" & CreateUUId();
				var parentEntityName        = "parentEntityName" & CreateUUId();
				var filterParams            = [
					  { name="entity_type"       , cfsqltype="varchar", value=entityType       }
					, { name="entity_name"       , cfsqltype="varchar", value=entityName       }
					, { name="parent_entity_name", cfsqltype="varchar", value=parentEntityName }
				];

				mockSqlAdapter.$( "getSelectSql" ).$args(
					  tableName     = versionTableName
					, selectColumns = [ "1" ]
					, filter        = filterSql
				).$results( dummySql );

				mockSqlRunner.$( "runSql" ).$args( sql=dummySql, dsn=mockDsn, params=filterParams ).$results( QueryNew( '' ) );

				expect( schemaVersioningService.versionExists(
					  entityType       = entityType
					, entityName       = entityName
					, parentEntityName = parentEntityName
				) ).toBe( false );
			} );

			it( "should return true if a db record exists for the given entity type, entity name and parent entity name", function(){
				var schemaVersioningService = _getVersioningService();
				var filterSql               = "entity_type = :entity_type and entity_name = :entity_name and parent_entity_name = :parent_entity_name";
				var dummySql                = "some dummy sql" & CreateUUId();
				var entityType              = "entityType" & CreateUUId();
				var entityName              = "entityName" & CreateUUId();
				var parentEntityName        = "parentEntityName" & CreateUUId();
				var filterParams            = [
					  { name="entity_type"       , cfsqltype="varchar", value=entityType       }
					, { name="entity_name"       , cfsqltype="varchar", value=entityName       }
					, { name="parent_entity_name", cfsqltype="varchar", value=parentEntityName }
				];

				mockSqlAdapter.$( "getSelectSql" ).$args(
					  tableName     = versionTableName
					, selectColumns = [ "1" ]
					, filter        = filterSql
				).$results( dummySql );

				mockSqlRunner.$( "runSql" ).$args( sql=dummySql, dsn=mockDsn, params=filterParams ).$results( QueryNew( 'a', 'int', [[1]] ) );

				expect( schemaVersioningService.versionExists(
					  entityType       = entityType
					, entityName       = entityName
					, parentEntityName = parentEntityName
				) ).toBe( true );
			} );

			it( "should check for NULL valued parent entity names when no parent entity name passed", function(){
				var schemaVersioningService = _getVersioningService();
				var filterSql               = "entity_type = :entity_type and entity_name = :entity_name and parent_entity_name is null";
				var dummySql                = "some dummy sql" & CreateUUId();
				var entityType              = "entityType" & CreateUUId();
				var entityName              = "entityName" & CreateUUId();
				var filterParams            = [
					  { name="entity_type"       , cfsqltype="varchar", value=entityType       }
					, { name="entity_name"       , cfsqltype="varchar", value=entityName       }
				];

				mockSqlAdapter.$( "getSelectSql" ).$args(
					  tableName     = versionTableName
					, selectColumns = [ "1" ]
					, filter        = filterSql
				).$results( dummySql );

				mockSqlRunner.$( "runSql" ).$args( sql=dummySql, dsn=mockDsn, params=filterParams ).$results( QueryNew( 'a', 'int', [[1]] ) );

				expect( schemaVersioningService.versionExists(
					  entityType       = entityType
					, entityName       = entityName
				) ).toBe( true );
			} );
		} );

		describe( "getSaveVersionSql", function(){
			it( "should return insert sql when version record does not already exist", function(){
				var schemaVersioningService = _getVersioningService();
				var versionHash             = CreateUUId();
				var entitytype              = CreateUUId();
				var entityName              = CreateUUId();
				var parentEntityName        = CreateUUId();
				var currentDate             = CreateUUId();
				var expectedSql             = "insert into #versionTableName# ( entity_type, entity_name, parent_entity_name, version_hash, date_modified ) values ( '#entityType#', '#entityName#', '#parentEntityName#', '#versionHash#', #currentDate# )";

				mockSqlAdapter.$( "getCurrentDateSql", currentDate );
				schemaVersioningService.$( "versionExists" ).$args( entityType=entityType, entityName=entityName, parentEntityName=parentEntityName ).$results( false );

				expect( schemaVersioningService.getSaveVersionSql(
					  entityType       = entityType
					, entityName       = entityName
					, parentEntityName = parentEntityName
					, versionHash      = versionHash
				) ).toBe( expectedSql );

			} );

			it( "should return insert sql with NULL parent entity value when no parent entity passed", function(){
				var schemaVersioningService = _getVersioningService();
				var versionHash             = CreateUUId();
				var entitytype              = CreateUUId();
				var entityName              = CreateUUId();
				var currentDate             = CreateUUId();
				var expectedSql             = "insert into #versionTableName# ( entity_type, entity_name, parent_entity_name, version_hash, date_modified ) values ( '#entityType#', '#entityName#', null, '#versionHash#', #currentDate# )";

				mockSqlAdapter.$( "getCurrentDateSql", currentDate );
				schemaVersioningService.$( "versionExists" ).$args( entityType=entityType, entityName=entityName, parentEntityName="" ).$results( false );

				expect( schemaVersioningService.getSaveVersionSql(
					  entityType       = entityType
					, entityName       = entityName
					, versionHash      = versionHash
				) ).toBe( expectedSql );

			} );

			it( "should return update sql when version record already exists", function(){
				var schemaVersioningService = _getVersioningService();
				var versionHash             = CreateUUId();
				var entitytype              = CreateUUId();
				var entityName              = CreateUUId();
				var parentEntityName        = CreateUUId();
				var currentDate             = CreateUUId();
				var expectedSql             = "update #versionTableName# set version_hash = '#versionHash#', date_modified = #currentDate# where entity_type = '#entityType#' and entity_name = '#entityName#' and parent_entity_name = '#parentEntityName#'";

				mockSqlAdapter.$( "getCurrentDateSql", currentDate );
				schemaVersioningService.$( "versionExists" ).$args( entityType=entityType, entityName=entityName, parentEntityName=parentEntityName ).$results( true );

				expect( schemaVersioningService.getSaveVersionSql(
					  entityType       = entityType
					, entityName       = entityName
					, parentEntityName = parentEntityName
					, versionHash      = versionHash
				) ).toBe( expectedSql );
			} );

			it( "should return update sql with null parent entity clause when version record already exists and no parent entity passed", function(){
				var schemaVersioningService = _getVersioningService();
				var versionHash             = CreateUUId();
				var entitytype              = CreateUUId();
				var entityName              = CreateUUId();
				var currentDate             = CreateUUId();
				var expectedSql             = "update #versionTableName# set version_hash = '#versionHash#', date_modified = #currentDate# where entity_type = '#entityType#' and entity_name = '#entityName#' and parent_entity_name is null";

				mockSqlAdapter.$( "getCurrentDateSql", currentDate );
				schemaVersioningService.$( "versionExists" ).$args( entityType=entityType, entityName=entityName, parentEntityName="" ).$results( true );

				expect( schemaVersioningService.getSaveVersionSql(
					  entityType       = entityType
					, entityName       = entityName
					, versionHash      = versionHash
				) ).toBe( expectedSql );
			} );
		} );

		describe( "saveVersion", function(){
			it( "should run whatever sql is returned by getSaveVersionSql() against the configured datasource", function(){
				var schemaVersioningService = _getVersioningService();
				var versionHash             = CreateUUId();
				var entitytype              = CreateUUId();
				var entityName              = CreateUUId();
				var parentEntityName        = CreateUUId();
				var dummySql                = CreateUUId();

				mockSqlRunner.$( "runSql" );
				schemaVersioningService.$( "getSaveVersionSql" ).$args(
					  versionHash      = versionHash
					, entitytype       = entitytype
					, entityName       = entityName
					, parentEntityName = parentEntityName
				).$results( dummySql );


				schemaVersioningService.saveVersion(
					  versionHash      = versionHash
					, entitytype       = entitytype
					, entityName       = entityName
					, parentEntityName = parentEntityName
				);

				var callLog = mockSqlRunner.$callLog().runSql;

				expect( callLog.len() ).toBe( 1 );
				expect( callLog[1] ).toBe( {
					  sql = dummySql
					, dsn = mockDsn
				} );
			} );
		} );

		describe( "getFieldVersionHash", function(){
			it( "it should return an MD5 hash of all the properties of the field that effect the database schema", function(){
				var schemaVersioningService = _getVersioningService();
				var field                   = { test=CreateUUId(), blah="test", name="test", maxlength=100, dbtype="varchar", required=false, uniqueindexes="blah", indexes="blah2", relationship="many-to-one", relatedto="john" };
				var fieldWithOnlyDbAttribs  = StructNew( "linked" );

				fieldWithOnlyDbAttribs.name          ="test";
				fieldWithOnlyDbAttribs.dbtype        ="varchar";
				fieldWithOnlyDbAttribs.maxlength     =100;
				fieldWithOnlyDbAttribs.required      =false;
				fieldWithOnlyDbAttribs.uniqueindexes ="blah";
				fieldWithOnlyDbAttribs.indexes       ="blah2";
				fieldWithOnlyDbAttribs.relationship  ="many-to-one";
				fieldWithOnlyDbAttribs.relatedto     ="john";

				var hashed = Hash( SerializeJson( fieldWithOnlyDbAttribs ) );

				expect( schemaVersioningService.getFieldVersionHash( field=field ) ).toBe( hashed );
			} );
		} );

		describe( "getObjectVersionHash"
			, function(){
			it( "should generate a version hash based on all of its database field version hashes", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObj                 = getMockBox().createStub();
				var mockFields              = StructNew( 'linked' );
				var expected                = "";

				mockFields.field1 = { versionHash=CreateUUId(), field={ test=CreateUUId() } };
				mockFields.field2 = { versionHash=CreateUUId(), field={ test=CreateUUId() } };
				mockFields.field3 = { versionHash=CreateUUId(), field={ test=CreateUUId() } };

				mockObj.$( "getObjectName", "test" );
				for( var fieldName in mockFields ) {
					mockObj.$( "getProperty" ).$args( propertyName=fieldName ).$results( mockFields[ fieldName ].field );
					schemaVersioningService.$( "getFieldVersionHash" ).$args( field=mockFields[ fieldName ].field ).$results( mockFields[ fieldName ].versionHash );
					expected &= mockFields[ fieldName ].versionHash;
				}
				mockTableFieldsHelper.$( "listTableFields", mockFields.keyArray() );

				expected = Hash( expected );

				var versionHash = schemaVersioningService.getObjectVersionHash( object=mockObj );

				expect( versionHash ).toBe( expected );
			} );
		} );

		describe( "getDatabaseVersionHash", function(){
			it( "should return a version hash based on the object hashes of all the objects in the passed object library", function(){
				var schemaVersioningService = _getVersioningService();
				var mb                      = getMockBox();
				var mockLibrary             = mb.createEmptyMock( "presidedataobjects.library.ObjectLibrary" );
				var mockObjNames            = [ "obj1", "obj2", "obj3" ];
				var mockObjs                = [ mb.createStub(), mb.createStub(), mb.createStub() ];
				var hashes                  = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var expectedVersionHash     = Hash( hashes.toList( "" ) );

				mockLibrary.$( "listObjects", mockObjNames );
				for( var i=1; i <= mockObjNames.len(); i++ ) {
					mockObjs[ i ].id = CreateUUId();
					mockLibrary.$( "getObject" ).$args( objectName=mockObjNames[i] ).$results( mockObjs[i] );
					schemaVersioningService.$( "getObjectVersionHash" ).$args( object=mockObjs[i] ).$results( hashes[i] );
				}

				expect( schemaVersioningService.getDatabaseVersionHash( objectLibrary=mockLibrary ) ).toBe( expectedVersionHash );
			} );
		} );

		describe( "hasDbVersionChanged", function(){
			it( "should return true when the version hash of the object library does not match the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockLibrary             = getMockBox().createEmptyMock( "presidedataobjects.library.ObjectLibrary" );
				var mockDbHash              = Hash( CreateUUId() );
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'db' and entity_name = 'db' and parent_entity_name is null";

				mockLibrary.id = CreateUUId();
				schemaVersioningService.$( "getDatabaseVersionHash" ).$args( objectLibrary=mockLibrary ).$results( mockDbHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ Hash( CreateUUId() ) ] ] ) );

				expect( schemaVersioningService.hasDbVersionChanged( objectLibrary=mockLibrary ) ).toBe( true );

			} );
			it( "should return false when the version hash of the object library matches the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockLibrary             = getMockBox().createEmptyMock( "presidedataobjects.library.ObjectLibrary" );
				var mockDbHash              = Hash( CreateUUId() );
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'db' and entity_name = 'db' and parent_entity_name is null";

				mockLibrary.id = CreateUUId();
				schemaVersioningService.$( "getDatabaseVersionHash" ).$args( objectLibrary=mockLibrary ).$results( mockDbHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ mockDbHash ] ] ) );

				expect( schemaVersioningService.hasDbVersionChanged( objectLibrary=mockLibrary ) ).toBe( false );
			} );

			it( "should return true when no version saved in the databse", function(){
				var schemaVersioningService = _getVersioningService();
				var mockLibrary             = getMockBox().createEmptyMock( "presidedataobjects.library.ObjectLibrary" );
				var mockDbHash              = Hash( CreateUUId() );
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'db' and entity_name = 'db' and parent_entity_name is null";

				mockLibrary.id = CreateUUId();
				schemaVersioningService.$( "getDatabaseVersionHash" ).$args( objectLibrary=mockLibrary ).$results( mockDbHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "" ) );

				expect( schemaVersioningService.hasDbVersionChanged( objectLibrary=mockLibrary ) ).toBe( true );

			} );
		} );


		describe( "hasObjectVersionChanged", function(){
			it( "should return true when the version hash of the object does not match the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'table' and entity_name = '#mockTablename#' and parent_entity_name is null";

				mockObject.id = CreateUUId();
				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getObjectVersionHash" ).$args( object=mockObject ).$results( mockHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ Hash( CreateUUId() ) ] ] ) );

				expect( schemaVersioningService.hasObjectVersionChanged( object=mockObject ) ).toBe( true );

			} );

			it( "should return false when the version hash of the object matches the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'table' and entity_name = '#mockTablename#' and parent_entity_name is null";

				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getObjectVersionHash", mockhash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ mockHash ] ] ) );

				expect( schemaVersioningService.hasObjectVersionChanged( object=mockObject ) ).toBe( false );

			} );

			it( "should return true when no version saved in the databse", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'table' and entity_name = '#mockTablename#' and parent_entity_name is null";

				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getObjectVersionHash", mockhash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "" ) );

				expect( schemaVersioningService.hasObjectVersionChanged( object=mockObject ) ).toBe( true );

			} );
		} );

		describe( "hasFieldVersionChanged", function(){
			it( "should return true when the version hash of the field does not match the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockField               = { name=CreateUUId(), test="fubar" };
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'field' and entity_name = '#mockField.name#' and parent_entity_name = '#mockTablename#'";

				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getFieldVersionHash" ).$args( field=mockField ).$results( mockHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ Hash( CreateUUId() ) ] ] ) );

				expect( schemaVersioningService.hasFieldVersionChanged( field=mockField, object=mockObject ) ).toBe( true );

			} );

			it( "should return false when the version hash of the field matches the version saved in the database", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockField               = { name=CreateUUId(), test="fubar" };
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'field' and entity_name = '#mockField.name#' and parent_entity_name = '#mockTablename#'";

				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getFieldVersionHash" ).$args( field=mockField ).$results( mockHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "version_hash", "varchar", [ [ mockHash ] ] ) );

				expect( schemaVersioningService.hasFieldVersionChanged( field=mockField, object=mockObject ) ).toBe( false );
			} );

			it( "should return true when no version saved in the databse", function(){
				var schemaVersioningService = _getVersioningService();
				var mockObject              = getMockBox().createStub();
				var mockField               = { name=CreateUUId(), test="fubar" };
				var mockHash                = Hash( CreateUUId() );
				var mockTablename           = CreateUUId();
				var expSql                  = "select version_hash from #versionTableName# where entity_type = 'field' and entity_name = '#mockField.name#' and parent_entity_name = '#mockTablename#'";

				mockObject.$( "getTablename", mockTablename );
				schemaVersioningService.$( "getFieldVersionHash" ).$args( field=mockField ).$results( mockHash );
				mockSqlRunner.$( "runSql" ).$args( sql=expSql, dsn=mockDsn ).$results( QueryNew( "" ) );

				expect( schemaVersioningService.hasFieldVersionChanged( field=mockField, object=mockObject ) ).toBe( true );
			} );
		} );
	}

/*********************************** PRIVATE HELPERS ***********************************/
	private function _getVersioningService() {
		variables.mockDbInfoService     = getMockBox().createEmptyMock( "presidedataobjects.db.DbInfoService" );
		variables.mockSqlAdapter        = getMockBox().createStub();
		variables.mockAdapterFactory    = getMockBox().createEmptyMock( "presidedataobjects.db.adapter.AdapterFactory" );
		variables.mockSqlRunner         = getMockBox().createEmptyMock( "presidedataobjects.db.SqlRunner" );
		variables.mockTableFieldsHelper = getMockBox().createEmptyMock( "presidedataobjects.db.helpers.ObjectTableFieldsHelper" );

		variables.mockAdapterFactory.$( "getAdapter" ).$args( dsn=mockDsn ).$results( mockSqlAdapter );

		return getMockBox().createMock(
			object = new presidedataobjects.db.schema.SchemaVersioningService(
				  dsn                     = mockdsn
				, dbInfoService           = mockDbInfoService
				, versionTableName        = versionTableName
				, adapterFactory          = mockAdapterFactory
				, sqlRunner               = mockSqlRunner
				, objectTableFieldsHelper = mockTableFieldsHelper
			)
		);
	}
}
