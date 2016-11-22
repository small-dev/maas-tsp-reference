include "console.iol"
include "string_utils.iol"
include "json_utils.iol"

outputPort Git {
  Location: "socket://raw.githubusercontent.com:443/small-dev/maas-tsp-reference/master/"
  Protocol: https {
    .osc.fetchSchema.alias -> address;
    // .debug = true;
    // .debug.showContent = true;
    .method = "get";
    .format = "json";
    .contentType = "application/json"
  }
  RequestResponse: fetchSchema
}

interface ConversionUtilsInterface {
  RequestResponse: convertType, convertID, visitProperty, assignCardinality, prettyStringType, prettyStringSubtype
}

main
{
  // debug = true;
  // address = "schemas/tsp/request-customer.json";
  address = "schemas/core/booking.json";
  fetchSchema@Git()( response );
  getJsonValue@JsonUtils( response )( js );
  // valueToPrettyString@StringUtils( js )( jsP );
  // println@Console( jsP )();
  // println@Console( "= = = = = = = = = = = = =" )();
  
  if( is_defined( js.type ) ) {
    split@StringUtils( js.id { .regex = "/" } )( splitID );
    js.definitions.( splitID.result[ #splitID.result-1 ] ) << js
  };
  foreach ( child : js.definitions ) {
    js.definitions.( child ).id = child;
    if( debug ) {
      valueToPrettyString@StringUtils( js.definitions.( child ) )( s );
      println@Console( s )();
      println@Console( ". . . . . . . . . . . . ." )()
    };
    convertType@ConversionUtils( js.definitions.( child ) )( jolieType );
    prettyStringType@ConversionUtils( jolieType )( stringType );
    if( debug ){
      valueToPrettyString@StringUtils( jolieType )( jTp );
      println@Console( jTp )();
      println@Console( ". . . . . . . . . . . . ." )()
    };
    println@Console( stringType )();
    println@Console( "\n" )()
  }
}

service ConversionUtils 
{
  Interfaces: ConversionUtilsInterface
  main 
  {
    [ convertType( req )( jolieType ){
      convertID@ConversionUtils( req.id )( jolieType.id );
      if ( !is_defined( req.type ) ){
        println@Console( "// WARNING: type \"" + jolieType.id + "\" has no type definition, assigning object")();
        req.type = "object"
      };
      if ( req.type == "object" ){
      jolieType.type = "void";
      foreach ( property : req.properties ) {
        visitProperty@ConversionUtils( req.properties.( property ) )( jolieType.nodes.( property ) )
      };
      if( is_defined( req.required ) ) {
        jolieType.required << req.required
      };
      assignCardinality@ConversionUtils( jolieType )( jolieType );
      if ( req.additionalProperties ){ 
        jolieType.undefined = true
      }
      } else if ( req.type == "number" ) {
        jolieType.type = "double"
      } else {
        jolieType.type = req.type
      }
    }]
    [ convertID( ID )( rID ){
      // gets filename
      // split@StringUtils( ID { .regex = "/" } )( splitID );
      // ID = "";
      // removes "-" and switches to CamelCase
      split@StringUtils( ID { .regex = "-" } )( splitID );
      for ( i=0, i<#splitID.result, i++ ) {
        split@StringUtils( splitID.result[ i ] { .regex = "^\\w" } )( subSplitID );
        substring@StringUtils( splitID.result[ i ] { .begin = 0, .end = 1 } )( subSplitID.result[ 0 ] );
        toUpperCase@StringUtils( subSplitID.result[ 0 ] )( subSplitID.result[ 0 ] );
        rID += subSplitID.result[ 0 ] + subSplitID.result[ 1 ]
      };
      rID += "Type"
    } ]
    [ assignCardinality( req )( req ){
      if( is_defined( req.required ) ){
        with ( req.nodes.( child ) ){
          foreach ( child : req.nodes ) {
            .required = false;
            for ( required in req.required ) {
              if( child == required )
                .required = true
            }
          }
        }
      };
      undef( req.required )
    }]
    [ visitProperty( property )( node ){
      if ( is_defined( property.( "$ref" ) ) ){
        split@StringUtils( property.( "$ref" ) { .regex = "/" } )( splitID );
        replaceAll@StringUtils( splitID.result[ #splitID.result-1 ] { .regex = "\\.json", .replacement = "" } )( splitID );
        convertID@ConversionUtils( splitID )( node.type )
      } else if ( property.type == "object" ){
        node.type = "void";
        foreach ( subproperty : property.properties ) {
          visitProperty@ConversionUtils( property.properties.( subproperty ) )( node.nodes.( subproperty ) )
        }
        // assignCardinality@ConversionUtils( js.required )( ); // may be empty
        // if ( js.additionalProperties ){ 
        //  add undefined type choice
        // }
      } else if ( node.type == "number" ) {
        node.type = "double"
      } else {
        node.type = property.type
      }
    }]
    [ prettyStringSubtype( req )( strType ){
      foreach ( child : req.nodes ) {
        strType += req.indent + "." + child;
        if( is_defined( req.nodes.( child ).required ) && !req.nodes.( child ).required ) {
          strType += "?"
        };
        strType += ": " + req.nodes.( child ).type;
        if( #req.nodes.( child ).nodes > 0 ){
          strType += " {\n";
          req.nodes.( child ).indent = req.indent + "  ";
          prettyStringSubtype@ConversionUtils( req.nodes.( child ) )( subtypes );
          strType += subtypes;
          strType += req.indent + "}"
      };
      strType += "\n"
    }}]
    [ prettyStringType( req )( strType ){
      strType = "type " + req.id + ": ";
      if ( is_defined( req.undefined ) ){
        strType += "undefined | "  
      };
      strType += req.type;
      if( #req.nodes > 0 ){
        req.indent = "  ";
        prettyStringSubtype@ConversionUtils( req )( subtypes );
        strType += " {\n" + subtypes + "}"
      }
    }]
  }
}