var search  = require("/MarkLogic/appservices/search/search.xqy");
var slib    = require("/app/lib/search-lib.xqy");
var ingest  = require("/app/lib/ingest.xqy");
var suggest = require("/app/lib/suggest-lib.xqy");

// GET
//
// This function returns a document node corresponding to each
// user-defined parameter in order to demonstrate the following
// aspects of implementing REST extensions:
// - Returning multiple documents
// - Overriding the default response code
// - Setting additional response headers
//
function get(context, params) {
  var results = [];
  context.outputTypes = [];

  context.outputStatus = [200, 'OK'];

  var pqtxt;

  var paramObj = getParameters(params);

  if (fn.stringLength(paramObj.pqtxt) > 0) {
    pqtxt = paramObj.pqtxt;
  } else {
    pqtxt = "";
  }

  var results = [];
  context.outputTypes = [];
  context.outputStatus = [200, 'OK'];
  
  var suggestions = [];

  if (fn.stringLength(pqtxt) > 0) {
  
    suggestions = getSuggestions(pqtxt);

  } else {
  
    suggestions = [];
  
  }

  var retObj =
    {
      suggestions: suggestions
    };

  return retObj;
};

// PUT
//
function put(context, params, input) {

  xdmp.log('PUT invoked');
  
  var results = [];
  context.outputTypes = [];
  context.outputStatus = [200, 'OK'];

  var suggestions = [
      "state:",
      "state:Alberta",
      "state:California",
      "state:Manitoba",
      "state:\"New Brunswick\"",
      "state:\"New York\"",
      "state:Saskatchewan"
  ];

  var retObj =
    {
      suggestions: suggestions
    };

  return retObj;
};

function post(context, params, input) {

  var results = [];
  context.outputTypes = [];
  context.outputStatus = [200, 'OK'];

  var retObj =
    {
      status: "POST Invoked"
    };

  return retObj;
};

function deleteFunction(context, params) {
  xdmp.log('DELETE invoked');

  var results = [];
  context.outputTypes = [];
  context.outputTypes.push('application/json');

  context.outputStatus = [201, 'OK'];
  
  var retStatus = ["Delete Invoked..."];
  
  var retObj =
  {
    status: retStatus
  };

  return retObj;
};

// PUT helper func that demonstrates working with input documents.
//
// It inserts a (nonsense) property into the incoming document if
// it is a JSON document and simply inserts the document unchanged
// if it is an XML document. Other doc types are skipped.
//
// Input documents are imutable, so you must call toObject()
// to create a mutable copy if you want to make a change.
//
// The property added to the JSON input is set to the current time
// just so that you can easily observe it changing on each invocation.
//
function doSomething(doc, docType, basename)
{
  var uri = '/extensions/' + basename;
  if (docType == 'application/json') {
    // create a mutable version of the doc so we can modify it
    var mutableDoc = doc.toObject();
    uri += '.json';

    // add a JSON property to the input content
    mutableDoc.written = fn.currentTime();
    xdmp.documentInsert(uri, mutableDoc);
    return uri;
  } else if (docType == 'application/xml') {
    // pass thru an XML doc unchanged
    uri += '.xml';
    xdmp.documentInsert(uri, doc);
    return uri;
  } else {
    return '(skipped)';
  }
};

function getParameters(params)
{
  var fileName, fileId, client, user, merge, uri, q, workPaperId, version, pqtxt;
  
  for (var pname in params) {
    if (params.hasOwnProperty(pname)) {
    
      xdmp.log("........... param: " + pname);
      xdmp.log("........... value: " + params[pname]);
      xdmp.log(" ");

      switch(pname) {
        case "filename":
        case "fileName":
          fileName = params[pname];
          break;
  
        case "client":
          client = params[pname];
          break;
  
        case "user":
        case "userid":
        case "userId":
          user = params[pname];
          break;

        case "merge":
          merge = params[pname];
          break;

        case "uri":
        case "Uri":
          uri = params[pname];
          break;

        case "id":
        case "Id":
          fileId = params[pname];
          break;

        case "q":
          q = params[pname];
          break;

        case "pqtxt":
          pqtxt = params[pname];
          break;

        case "workPaperId":
        case "workpaperid":
          workPaperId = params[pname];
          break;

        case "version":
        case "Version":
          version = params[pname];
          break;

        default:
          break;
      }
    }
  }
  
  var retObj =
    {
      fileName: fileName,
      fileId: fileId,
      client: client,
      user: user,
      merge: merge,
      uri: uri,
      q: q,
      version: version,
      workPaperId: workPaperId,
      pqtxt: pqtxt
    };

  return retObj;
};

function getSuggestions(pqtxt)
{
  var suggestions;

  suggestions = suggest.getSuggestions(pqtxt);

  return suggestions;
};

// Helper function that demonstrates how to normalize inputs
// that may or may not be multi-valued, such as the 'input'
// param to your methods.
//
// In cases where you might receive either a single value
// or a ValueIterator, depending on the request context,
// you can normalize the data type by creating a ValueIterator
// from the single value.
function normalizeInput(item)
{
  return (item instanceof ValueIterator)
         ? item                        // many
         : xdmp.arrayValues([item]);   // one
};

// Helper function that demonstrates how to return an error response
// to the client.

// You MUST use fn.error in exactly this way to return an error to the
// client. Raising exceptions or calling fn.error in another manner
// returns a 500 (Internal Server Error) response to the client.
function returnErrToClient(statusCode, statusMsg, body)
{
  fn.error(null, 'RESTAPI-SRVEXERR', 
           xdmp.arrayValues([statusCode, statusMsg, body]));
  // unreachable - control does not return from fn.error.
};


// Include an export for each method supported by your extension.
exports.GET = get;
exports.POST = post;
exports.PUT = put;
exports.DELETE = deleteFunction;
