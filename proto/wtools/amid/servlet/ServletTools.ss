(function _ServletTools_ss_()
{

'use strict';

/**
 * Collection of cross-platform routines to launch / stop server and handle requests from server. The module is trying to make development of server-sde applications simpler.Collection of cross-platform routines to launch/stop the server and handle requests to the server. The module is trying to make the development of server-side applications simpler.
  @module Tools/mid/ServletTools
*/

/**
 *@summary Collection of cross-platform routines to launch/stop the server and handle requests to the server.
  @namespace Tools.wServletTools
  @memberof module:Tools/mid/ServletTools
*/

let Querystring = null;
let Https = null;
let Http = null;
let Express = null;

const _ = require( '../../../node_modules/Tools' );

_.include( 'wUriBasic' );
_.include( 'wFiles' );
_.include( 'wConsequence' );

_.servlet = _.servlet || Object.create( null );

// --
// servlet
// --

function serverPathParse( o )
{
  let uri;

  _.routine.options_( serverPathParse, arguments );

  let parsed = _.uri.parseAtomic( o.full );

  parsed.port = parsed.port || o.port || 5000;
  if( _.strIs( parsed.port ) )
  parsed.port = Number( parsed.port );
  _.sure( _.numberIsFinite( parsed.port ), () => 'Expects number {-o.port-}, but got ' + _.entity.exportStringDiagnosticShallow( parsed.port ) );

  parsed.full = _.uri.str( parsed );

  parsed = _.uri.parseFull( parsed.full );
  parsed.port = Number( parsed.port );
  parsed.resourcePath = parsed.resourcePath || '/';

  /* xxx qqq : use _.uri.parsedSupplementFull instead of parseFull */

  return parsed;
}

serverPathParse.defaults =
{
  full : 'http://127.0.0.1:5000',
  port : null,
}

//

function controlExpressStart( o )
{
  let uri;

  _.routine.options_( controlExpressStart, arguments );
  _.assert( !!o.name, 'Expects {-name-}' );
  _.assert( _.boolLike( o.usingHttps ), 'Expects {-o.usingHttps-}' );
  _.assert( _.boolLike( o.allowCrossDomain ), 'Expects {-o.allowCrossDomain-}' );

  if( !_.numberIs( o.verbosity ) )
  o.verbosity = o.verbosity ? 1 : 0;
  if( o.verbosity < 0 )
  o.verbosity = 0;
  else if( o.verbosity > 9 )
  o.verbosity = 9;
  _.assert( o.verbosity >= 0, 'Expects number {-o.verbosity-}' );

  if( !Express )
  Express = require( 'express' );

  let parsedServerPath = _.servlet.serverPathParse({ port : o.port, full : o.serverPath });
  o.serverPath = parsedServerPath.full;
  o.port = parsedServerPath.port;
  _.sure( _.numberIsFinite( o.port ), () => 'Expects number {-o.port-}, but got ' + _.entity.exportStringDiagnosticShallow( o.port ) );

  if( !o.express )
  o.express = Express();

  if( o.server )
  return o;

  if( o.usingHttps )
  {

    if( !Https )
    Https = require( 'https' );

    uri = o.serverPath + ':' + o.port;

    o.httpsOptions = o.httpsOptions || Object.create( null );
    _.assert( o.certificatePath );

    o.httpsOptions.key = o.httpsOptions.key || _.fileProvider.fileRead( o.certificatePath + '.rsa' );
    o.httpsOptions.cert = o.httpsOptions.cert || _.fileProvider.fileRead( o.certificatePath + '.crt' );

    o.server = Https.createServer( httpsOptions, o.express ).listen( o.port, parsedServerPath.host );

  }
  else
  {

    if( !Http )
    Http = require( 'http' );

    uri = o.serverPath + ':' + o.port;
    o.server = Http.createServer( o.express ).listen( o.port, parsedServerPath.host );

  }

  if( o.verbosity >= 3 )
  logger.log( o.name, ':', 'express.locals :', '' + _.entity.exportStringNice( o.express.locals ) );
  if( o.verbosity )
  logger.log( o.name, ':', `serving at ${o.serverPath}..`, '\n' )

  return o;
}

controlExpressStart.defaults =
{

  verbosity : 1,
  name : null,
  serverPath : 'http://127.0.0.1',
  port : null,
  allowCrossDomain : 0,

  server : null,
  express : null,

  usingHttps : 0,
  httpsOptions : null,
  certificatePath : null,

}

//

function controlPathesNormalize( o )
{

  _.routine.options_( controlPathesNormalize, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  /* uri */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'uri' ) )
    {
      if( !component )continue;
      o.servlet[ c ] = _.path.normalize( o.servlet[ c ] );
    }
  }

  /* path */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'path' ) )
    {
      if( !component )continue;
      o.servlet[ c ] = _.path.normalize( o.servlet[ c ] );
    }
  }

}

controlPathesNormalize.defaults =
{
  servlet : null,
}

//

function controlAllowCrossDomain( o )
{

  _.routine.options_( controlAllowCrossDomain, arguments );

  o.response.setHeader( 'Access-Control-Allow-Origin', '*' );
  o.response.setHeader( 'Access-Control-Allow-Headers', 'X-Requested-With' );
  o.response.setHeader( 'Access-Control-Allow-Methods', 'GET,  PUT,  POST,  DELETE' );

}

controlAllowCrossDomain.defaults =
{
  response : null,
}

//

function controlRequestPreHandle( o )
{

  if( o.allowCrossDomain )
  _.servlet.controlAllowCrossDomain({ response : o.response });

  if( o.verbosity >= 2 )
  logger.log( 'request : ' + _.servlet.requestUriFullGet( o.request ) );

}

controlRequestPreHandle.defaults =
{
  allowCrossDomain : 0,
  verbosity : 1,
  request : null,
  response : null,
  next : null,
}

//

function controlRequestPostHandle( o )
{
  _.routine.options_( controlRequestPostHandle, arguments );

  // if( o.response.finished )
  // return o.next( o.request, o.response, o.next );

  if( o.response.finished )
  return;

  // debugger;
  return _.servlet.errorHandle
  ({
    request : o.request,
    response : o.response,
    verbosity : o.verbosity,
    err : _.errBrief( `${o.response.req.method} ${o.request.url} - Not found!` ),
  });

}

controlRequestPostHandle.defaults =
{
  verbosity : 1,
  request : null,
  response : null,
  next : null,
}

//

function controlLoggingPre( o )
{

  _.routine.options_( controlLoggingPre, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  if( !o.servlet.verbosity )
  return;

  if( o.servlet.verbosity > 2 )
  {
    logger.log( '' );
    logger.logUp( _.strQualifiedName( o.servlet ), ' :' );
    logger.logDown( '' );
  }

}

controlLoggingPre.defaults =
{
  servlet : null,
}

//

function controlLoggingPost( o )
{

  _.routine.options_( controlLoggingPost, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  if( !o.servlet.verbosity )
  return;

  logger.logUp( 'Properties of', _.strQualifiedName( o.servlet ) );

  /* db */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'db' ) )
    {
      logger.log( c, ' :', component );
    }
  }

  /* uri */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'uri' ) )
    {
      logger.log( c, ' :', component );
    }
  }

  /* path */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'path' ) )
    {
      logger.log( c, ' :', component );
    }
  }

  logger.logDown( '' );

}

controlLoggingPost.defaults =
{
  servlet : null,
}

// --
//
// --

function requestUriFullGet( request )
{
  _.assert( arguments.length === 1 );
  let result = request.protocol + ':///' + request.get( 'host' ) + request.originalUrl;
  return result;
}

//

function errorHandle( o )
{
  if( !o.err )
  o.err = _.errBrief( 'Not found' );
  o.err = _.err( o.err );

  _.routine.options_( errorHandle, arguments );

  if( !o.response.finished )
  {
    o.response.writeHead( 400, { 'Content-Type' : 'text/plain' });
    o.response.write( o.err.message );
    o.response.end();
  }

  if( o.verbosity )
  _.errLogOnce( o.err );

  return o.err;
}

errorHandle.defaults =
{
  request : null,
  response : null,
  err : null,
  verbosity : 1,
}

//

function postDataGet( o )
{
  let con = _.Consequence();

  _.routine.options_( postDataGet, arguments );
  _.assert( _.longHas( [ 'querystring', 'json' ], o.mode ) )

  if( o.mode === 'querystring' )
  {
    if( !Querystring )
    Querystring = require( 'querystring' );
  }

  if( o.request.readable )
  {

    o.request.data = '';

    o.request.on( 'data', function( data )
    {
      if( o.request.data.length + data.length > o.sizeLimit )
      {
        let err = _.err( `Request entity is too large ${o.request.data.length}\nsizelimit is ${o.sizeLimit}` );
        o.response.json( { error : err.message }, 413 );
        con.error( err );
      }
      o.request.data += data;
    });

    o.request.on( 'end', function()
    {
      if( o.mode === 'json' )
      {
        o.request.data = decodeURIComponent( o.request.data );
        o.request.data = JSON.parse( o.request.data );
      }
      else if( o.mode === 'querystring' )
      {
        o.request.data = Querystring.parse( o.request.data );
      }
      else _.assert( 0 );
      con.take( o.request.data );
    });

  }
  else
  {

    o.request.data = o.request.body;
    con.take( o.request.body );

  }

  return con;
}

postDataGet.defaults =
{
  sizeLimit : 1e6,
  request : null,
  response : null,
  mode : 'querystring',
}

// --
// declare
// --

let Proto =
{

  // servlet

  serverPathParse,

  controlExpressStart, /* qqq : basic coverage required */
  controlPathesNormalize,
  controlAllowCrossDomain,

  controlRequestPreHandle,
  controlRequestPostHandle,
  controlLoggingPre,
  controlLoggingPost,

  requestUriFullGet,
  errorHandle,
  postDataGet,

}

/* _.props.extend */Object.assign( _.servlet, Proto );

// --
// export
// --

if( typeof module !== 'undefined' )
module[ 'exports' ] = _.servlet;

})();
