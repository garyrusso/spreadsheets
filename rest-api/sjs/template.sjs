var search = require("/MarkLogic/appservices/search/search.xqy");
var slib   = require("/app/lib/search-lib.xqy");
var ingest = require("/app/lib/ingest.xqy");

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
  
  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  
  xdmp.addResponseHeader("Content-Disposition", 'attachment; filename="workpaper.xlsx"');
  context.outputStatus = [200, 'OK'];
  
  var client = "ey001";
  var templateName, returnDoc, uri;
  
  for (var pname in params) {
    if (params.hasOwnProperty(pname) && pname === "templateName") {
      xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
      templateName = params[pname];
    }
  }

  if (fn.stringLength(templateName) > 0) {
    uri = slib.getTemplateUri(client, templateName).xpath("/binFileUri/text()");

    xdmp.log("GR Test 001: uri: " + uri);

    if (uri.toString() === "Template File does not exist") {
      returnDoc = "Invalid Template Id";
    } else {
      returnDoc = fn.doc(uri);
    }
  }
  
  return returnDoc;

/*
return
  try {
    xdmp.documentInsert("/foo.json", {"foo": "bar"} );
  } catch (err) {
    err.toString();
  }
 
  return
    document {
      try {
        $returnDoc
      } catch ($e) {
        element error { $e/error:message }
      }
    }
*/
};

// PUT
//
// The client should pass in one or more documents, and for each
// document supplied, a value for the 'basename' request parameter.
// The function inserts the input documents into the database only 
// if the input type is JSON or XML. Input JSON documents have a
// property added to them prior to insertion.
//
// Take note of the following aspects of this function:
// - The 'input' param might be a document node or a ValueIterator
//   over document nodes. You can normalize the values so your
//   code can always assume a ValueIterator.
// - The value of a caller-supplied parameter (basename, in this case)
//   might be a single value or an array.
// - context.inputTypes is always an array
// - How to return an error report to the client
//
function put(context, params, input) {
  xdmp.log('PUT invoked');
  return null;
};

function post(context, params, input) {

  //xdmp.log('POST invoked');

  var results = [];
  context.outputTypes = [];
  
  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  
  //xdmp.addResponseHeader("Content-Disposition", 'attachment; filename="workpaper.xlsx"');
  context.outputStatus = [200, 'OK'];
  
  var client = "ey001";
  var templateName, returnDoc, uri;

  var binDoc = normalizeInput(input);

  var userName         = ingest.getUserFullNameJson();
  var userTempFullName = userName.toString();
  var temp, firstName, lastName, user, trimmedFirstName, trimmedLastName;
  
  temp = fn.substringAfter(userTempFullName, "{\"firstName\":\"");
  firstName = fn.substringBefore(temp, "\",\"lastName");
  lastName  = fn.tokenize(fn.substringAfter(temp, "lastName\":\""), '"').toArray()[0];
  
  userFullName = firstName + ' ' + lastName;
  
  firstName = firstName.replace(/\s/g,'');
  firstName = firstName.replace(/\./g,'');
  firstName = firstName.replace(/\'/g,'');
  
  lastName = lastName.replace(/\s/g,'');
  lastName = lastName.replace(/\./g,'');
  lastName = lastName.replace(/\'/g,'');
  
  user = fn.lowerCase(firstName + lastName);

  for (var pname in params) {
    if (params.hasOwnProperty(pname) && pname === "templateName") {
      xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
      templateName = params[pname];
    }
  }

  if (fn.stringLength(templateName) > 0) {
  }
  
  var templateDir, templateMetadataDir, hashedUri, doc;
  
  templateDir = "/client/" + client + "/template";
  
  templateMetadataDir = templateDir + "/" + templateName;

  templateMetadataUri = templateMetadataDir + "/" + templateName + ".xml";
  templateBinFileUri  = templateMetadataDir + "/" + templateName + ".xlsx";

  hashedTemplateUri = xdmp.hash64(templateMetadataDir);

  xdmp.log("GR001 - templateMetadataUri: " + templateMetadataUri)
  xdmp.log("GR001 - templateBinFileUri:  " + templateBinFileUri)
  xdmp.log("GR001 - hashedTemplateUri:   " + hashedTemplateUri)
  xdmp.log("GR001 - userFullName: " + userFullName);
  xdmp.log("GR001 - user:         " + user);

  doc = ingest.extractSpreadsheetData(client, userFullName, user, templateBinFileUri, "", binDoc);

  return doc;

/*
      let $evalCmd :=
        fn:concat
        (
          'declare variable $metaUri external;
           declare variable $doc external;
           declare variable $uri external;
           declare variable $binDoc external;
           xdmp:document-insert($metaUri, $doc, xdmp:default-permissions(), ("spreadsheet")),
           xdmp:document-insert($uri, $binDoc, xdmp:default-permissions(), ("binary"))'
        )
    
      let $evalDoc :=
        xdmp:eval(
          $evalCmd,
          (xs:QName("metaUri"), $templateMetadataUri, xs:QName("doc"), $doc, xs:QName("uri"), $templateBinFileUri, xs:QName("binDoc"), $binDoc)
        )
        
      let $doc :=
        element { "response" }
        {
          element { "input" }
          {
            element { "dnameCount" } { fn:count($doc/tax:feed/tax:definedNames/tax:definedName) }
          },
          element { "status" }
          {
            element { "elapsedTime" }         { xdmp:elapsed-time() },
            element { "templateBinFileUri" }  { $templateBinFileUri },
            element { "templateMetadataUri" } { $templateMetadataUri }
          }
        }
        
      return $doc
    )

  return
    document
    {
      $response
    }
 */
};

function deleteFunction(context, params) {
  xdmp.log('POST invoked');
  return null;
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
