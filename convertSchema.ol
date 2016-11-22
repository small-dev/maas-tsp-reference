include "console.iol"
include "string_utils.iol"
include "json_utils.iol"

outputPort Git {
  Location: "socket://raw.githubusercontent.com:443/small-dev/maas-tsp-reference/master/"
  Protocol: https {
    .osc.fetchSchema.alias -> address;
    .debug = true;
    .debug.showContent = true;
    .method = "get";
    .format = "json";
    .contentType = "application/json"
  }
  RequestResponse: fetchSchema
}

interface ConversionUtilsInterface {
  RequestResponse: convertID, visitProperty, assignCardinality, prettyStringType, prettyStringSubtype
}

main
{
  address = "schemas/tsp/request-customer.json";
  fetchSchema@Git()( response );
  getJsonValue@JsonUtils( response )( js );
  println@Console( "= = = = = = = = = = = = =" )();
  convertID@ConversionUtils( js.id )( jolieType.id );
  if ( js.type == "object" ){
    jolieType.type = "void";
    foreach ( property : js.properties ) {
      visitProperty@ConversionUtils( js.properties.( property ) )( jolieType.nodes.( property ) )
    };
    jolieType.required << js.required;
    assignCardinality@ConversionUtils( jolieType )( jolieType );
    if ( js.additionalProperties ){ 
      jolieType.undefined = true
    }
  } else if ( js.type == "number" ) {
    jolieType.type = "double"
  } else {
    jolieType.type = js.type
  };

  prettyStringType@ConversionUtils( jolieType )( stringType );

  valueToPrettyString@StringUtils( js )( jsP );
  valueToPrettyString@StringUtils( jolieType )( jTp );
  println@Console( jsP + "\n = = = = = = = = \n" + jTp + "\n = = = = = = = = \n" + stringType )()
}

service ConversionUtils 
{
  Interfaces: ConversionUtilsInterface
  main 
  {
    [ convertID( ID )( ID ){
        // gets filename
      split@StringUtils( ID { .regex = "/" } )( splitID );
      ID = "";
      // removes "-" and switches to CamelCase
      split@StringUtils( splitID.result[ #splitID.result-1 ] { .regex = "-" } )( splitID );
      for ( i=0, i<#splitID.result, i++ ) {
        split@StringUtils( splitID.result[ i ] { .regex = "^\\w" } )( subSplitID );
        substring@StringUtils( splitID.result[ i ] { .begin = 0, .end = 1 } )( subSplitID.result[ 0 ] );
        toUpperCase@StringUtils( subSplitID.result[ 0 ] )( subSplitID.result[ 0 ] );
        ID = ID + subSplitID.result[ 0 ] + subSplitID.result[ 1 ]
      };
      ID = ID + "Type"
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
      if ( property.type == "object" ){
        node.type = "void";
        foreach ( subproperty : property.properties ) {
          visitProperty@ConversionUtils( property.( subproperty ) )( node.nodes.( subproperty ) )
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
        if( !req.nodes.( child ).required ) {
          strType += "?"
        };
        strType += ": " + req.nodes.( child ).type;
        if( #req.nodes.( child ).nodes > 0 ){
          strType += " {\n";
          req.nodes.( child ).indent = req.indent + "  ";
          prettyStringSubtype@ConversionUtils( req.nodes.( child ) )( subtypes );
          strType += subtypes;
          strType += "}"
      };
      strType += "\n"
    }}]
    [ prettyStringType( req )( strType ){
      strType = "type " + req.id + ": " + req.type;
      if( #req.nodes > 0 ){
        req.indent = "  ";
        prettyStringSubtype@ConversionUtils( req )( subtypes );
        strType += " {\n" + subtypes + "}"
      }
    }]
  }
}