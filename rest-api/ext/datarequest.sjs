var search = require("/MarkLogic/appservices/search/search.xqy");
var slib   = require("/app/lib/search-lib.xqy");
var ingest = require("/app/lib/ingest.xqy");

var tax = "http://tax.thomsonreuters.com";
var NS  = "http://tax.thomsonreuters.com";

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

  xdmp.log("GR001 - GET Data Request");

  var results = [];
  context.outputTypes = [];
  
  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  
  xdmp.addResponseHeader("Content-Disposition", 'attachment; filename="workpaper.xlsx"');
  context.outputStatus = [200, 'OK'];
  
  var client = "ey001";
  var requestId, returnDoc, uri, merge;
  
  for (var pname in params) {
      if (params.hasOwnProperty(pname) && pname === "id") {
        xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
        requestId = params[pname];
      } else {
        if (params.hasOwnProperty(pname) && pname === "uri") {
          xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
          uri = params[pname];
        } else {
          if (params.hasOwnProperty(pname) && pname === "merge") {
            xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
            merge = params[pname];
          }
      }
    }
  }

  if (fn.stringLength(requestId) > 0) {
  
    xdmp.log("GR Test 001: requestId: " + requestId);

  }
  
  var json = xdmp.unquote('{"name": "Oliver", "scores": [88, 67, 73], "isActive": true, "affiliation": null}').next().value; // Returns a ValueIterator
  
  return json.toObject();
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

  xdmp.log('POST invoked');

  var results = [];
  context.outputTypes = [];
  
  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  
  //xdmp.addResponseHeader("Content-Disposition", 'attachment; filename="workpaper.xlsx"');
  context.outputStatus = [200, 'OK'];
  
  var client = "ey001";
  var templateId, returnDoc, uri;

  var inputDoc = normalizeInput(input);

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
    if (params.hasOwnProperty(pname) && pname === "id") {
      xdmp.log("GR Test 001: pname: " + pname + " | param: " + params[pname]);
      templateId = params[pname];
    }
  }

  if (fn.stringLength(templateId) > 0) {
  }
  
  var requestDir, requestUri, hashedUri, templateName;

  var doc = slib.createUserDataDoc(client, user, templateId, "", inputDoc);
  
  var userDataId = doc.xpath("/*:meta/*:userDataId/text()");

  xdmp.log("1 ----- userDataId: " + userDataId);
//  var uri = "/client/" + client + "/user/" + userDataId + ".xml"

  requestDir = "/client/" + client + "/datarequest/" + slib.getTemplateName(templateId);
  
  hashedUri = xdmp.hash64(requestDir + JSON.stringify(inputDoc));

  requestUri = requestDir + "/" + hashedUri + ".json";

  xdmp.log("GR001 - requestDir:   " + requestDir)
  xdmp.log("GR001 - hashedUri:    " + hashedUri)
  xdmp.log("GR001 - requestUri:   " + requestUri)
  xdmp.log("GR001 - userFullName: " + userFullName);
  xdmp.log("GR001 - user:         " + user);

  var evalCmd =
      'declareUpdate();\n' +
      'var uri, doc;\n' +
      'xdmp.documentInsert(uri, doc, xdmp.defaultPermissions(), ("userdata"));'

  var evalDoc =
    xdmp.eval(
      evalCmd,
      {
        uri: requestUri,
        doc: inputDoc
      }
    );

  return "Document Inserted: " + requestUri;
  
/*
  return
    try {
      declareUpdate();
      xdmp.documentInsert(templateMetadataUri, doc);
    } catch (err) {
      err.toString();
    }
 */
};

function deleteFunction(context, params) {
  xdmp.log('DELETE invoked');
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

function getDataRequestList(client, id)
{
  var doc;
  
  var query = cts.and-query((
                  cts.collection-query(("spreadsheet")),
                  cts.element-value-query(fn.QName(NS, "templateId"), id)
                ));
                
  var results = cts.search(fn.doc(), query);

/*
  if (fn.count(results) > 0) {
    
  }
      element { "templateInfo" }
      {
        element { "binFileUri" } { $results[1]/tax:workbook/tax:meta/tax:file/text() },
        element { "metadataUri" } { xdmp:node-uri($results[1]) }
      }
    else
      element { "templateInfo" }
      {
        element { "binFileUri" } { "Template File does not exist" },
        element { "metadataUri" } { "Template Metadata File does not exist" }
      }

  return $doc
 */
  return "done";
};

// Include an export for each method supported by your extension.
exports.GET = get;
exports.POST = post;
exports.PUT = put;
exports.DELETE = deleteFunction;
