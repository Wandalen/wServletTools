(function _ServletTools_ss_() {

'use strict';

/**
 * Collection of routines to launch / stop server and handle requests from server. The module is trying to make development of server-sde applications simpler.Collection of routines to launch/stop the server and handle requests to the server. The module is trying to make the development of server-side applications simpler.
  @module Tools/mid/ServletTools
*/

/**
 *@summary Collection of routines to launch/stop the server and handle requests to the server.
  @namespace Tools( module::wServletTools )
  @memberof module:Tools/mid/ServletTools
*/

let Querystring = null;
let Https = null;
let Http = null;
let Express = null;

let _ = require( '../Tools.s' );
let _ = _global_.wTools;

_.include( 'wPathFundamentals' );
_.include( 'wFiles' );
_.include( 'wConsequence' );

let Parent = null;
let Self = _.servlet = _.servlet || Object.create( null );

// --
// servlet
// --

function controlLoggingPre()
{

  _.routineOptions( controlLoggingPre, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  if( !o.servlet.verbosity )
  return;

  if( o.servlet.verbosity > 2 )
  {
    logger.log( '' );
    logger.logUp( _.strNickName( o.servlet ), ' :' );
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

  _.routineOptions( controlLoggingPre, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  if( !o.servlet.verbosity )
  return;

  logger.logUp( 'Properties of', _.strNickName( o.servlet ) );

  /* db */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'db' ) )
    {
      logger.log( c,  ' :',  component );
    }
  }

  /* url */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'url' ) )
    {
      logger.log( c,  ' :',  component );
    }
  }

  /* path */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'path' ) )
    {
      logger.log( c,  ' :',  component );
    }
  }

  logger.logDown( '' );

}

controlLoggingPost.defaults =
{
  servlet : null,
}

//

function controlPathesNormalize( o )
{

  _.routineOptions( controlLoggingPre, arguments );
  _.assert( o.servlet.verbosity !== undefined, 'Expects { verbosity }' );

  /* url */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'url' ) )
    {
      if( !component ) continue;
      o.servlet[ c ] = _.path.normalize( o.servlet[ c ] );
    }
  }

  /* path */

  for( let c in o.servlet )
  {
    let component = o.servlet[ c ];
    if( _.strIs( component ) && _.strBegins( c, 'path' ) )
    {
      if( !component ) continue;
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

  _.routineOptions( controlAllowCrossDomain, arguments );

  o.response.setHeader( 'Access-Control-Allow-Origin',  '*' );
  o.response.setHeader( 'Access-Control-Allow-Headers',  'X-Requested-With' );
  o.response.setHeader( 'Access-Control-Allow-Methods',  'GET,  PUT,  POST,  DELETE' );

}

controlAllowCrossDomain.defaults =
{
  response : null,
}

//

function controlExpressStart( o )
{
  let url;

  _.routineOptions( controlExpressStart, arguments );
  _.assert( !!o.name, 'Expects { name }' );
  _.assert( !!o.port, 'Expects { port }' );
  _.assert( _.boolLike( o.usingHttps ), 'Expects { usingHttps }' );
  _.assert( _.boolLike( o.allowCrossDomain ), 'Expects { allowCrossDomain }' );
  _.assert( _.boolLike( o.verbosity ), 'Expects { verbosity }' );

  if( !Express )
  Express = require( 'express' );

  if( !o.port )
  return;

  if( !o.express )
  o.express = Express();

  if( o.server )
  return o;

  if( o.usingHttps )
  {

    if( !Https )
    Https = require( 'https' );

    url = o.serverPath + ':' + o.port;

    o.httpsOptions = o.httpsOptions || Object.create( null );
    _.assert( o.certificatePath );

    o.httpsOptions.key = o.httpsOptions.key || _.fileProvider.fileRead( o.certificatePath + '.rsa' );
    o.httpsOptions.cert = o.httpsOptions.cert || _.fileProvider.fileRead( o.certificatePath + '.crt' );

    o.server = Https.createServer( httpsOptions, o.express ).listen( o.port );

  }
  else
  {

    if( !Http )
    Http = require( 'http' );

    url = o.serverPath + ':' + o.port;
    o.server = Http.createServer( o.express ).listen( o.port );

  }

  if( o.verbosity >= 2 )
  logger.log( o.name,  ':',  'express.locals :', '\n' + _.toStrNice( o.express.locals ) );
  if( o.verbosity )
  logger.log( o.name,  ':',  'Serving', o.name, 'on', o.port, 'port..', '\n' )

  return o;
}

controlExpressStart.defaults =
{

  verbosity : 1,
  name : null,
  serverPath : 'http://127.0.0.1',
  port : null,
  allowCrossDomain : 0,
  verbosity : 1,

  server : null,
  express : null,

  usingHttps : 0,
  httpsOptions : null,
  certificatePath : null,

}

//

function controlRequestPreHandle( o )
{

  if( o.allowCrossDomain )
  _.servlet.controlAllowCrossDomain({ response : o.response });

  if( o.verbosity >= 2 )
  logger.log( 'request : ' + _.servlet.requestUrlGet( o.request ) );

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
  _.routineOptions( controlRequestPostHandle, arguments );

  if( o.response.finished )
  return o.next( o.request, o.response, o.next );

  _.servlet.errorHandle
  ({
    request : o.request,
    response : o.response,
    err : 'Not found',
    verbosity : o.verbosity,
  });

}

controlRequestPostHandle.defaults =
{
  allowCrossDomain : 0,
  verbosity : 1,
  request : null,
  response : null,
  next : null,
}

//

function requestUrlGet( request )
{
  _.assert( arguments.length === 1 );
  let result = request.protocol + '://' + request.get( 'host' ) + request.originalUrl;
  return result;
}

//

function errorHandle( o )
{
  let err = _.err( o.err || 'Not found' );

  _.routineOptions( errorHandle, arguments );

  if( !o.response.finished )
  {
    o.response.writeHead( 400, { 'Content-Type' : 'text/plain' });
    o.response.write( 'Error :\n' + err.message );
    o.response.end();
  }

  if( o.verbosity )
  _.errLogOnce( err );

  return err;
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

  _.routineOptions( postDataGet, arguments );
  _.assert( _.arrayHas( [ 'querystring',  'json' ],  o.mode ) )

  if( o.mode === 'querystring' )
  {
    if( !Querystring )
    Querystring = require( 'querystring' );
  }

  let o = o || {};

  if( o.request.readable )
  {

    o.request.data = '';

    o.request.on( 'data',  function( data )
    {
      if( o.request.data.length + data.length > o.sizeLimit )
      {
        debugger;
        let err = _.err( `Request entity is too large ${o.request.data.length}\nsizelimit is ${o.sizeLimit}` );
        o.response.json( { error : err.message },  413 );
        con.error( err );
      }
      o.request.data += data;
    });

    o.request.on( 'end',  function()
    {
      if( o.mode === 'json' )
      {
        o.request.data = decodeURIComponent( o.request.data );
        o.request.data = JSON.parse( o.request.data );
      }
      else if ( o.mode === 'querystring' )
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

  controlLoggingPre,
  controlLoggingPost,

  controlPathesNormalize,
  controlAllowCrossDomain,
  controlExpressStart, /* qqq : basic coverage required */

  controlRequestPreHandle,
  controlRequestPostHandle,

  requestUrlGet,
  errorHandle,
  postDataGet,

}

_.mapExtend( Self, Proto );

// --
// export
// --

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
