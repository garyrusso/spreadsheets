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

  //xdmp.log("GR001 - GET file Request");

  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  
  xdmp.addResponseHeader("Content-Disposition", 'attachment; filename="workpaper.xlsx"');
  context.outputStatus = [200, 'OK'];

  var client = "ey001";
  var fileName, uri, qString, id, doc, retObj, workPaperId;

  var paramObj = getParameters(params);

  if (fn.stringLength(paramObj.fileName) > 0) {
    fileName = paramObj.fileName;
  } else {
    fileName = "";
  }

  if (fn.stringLength(paramObj.q) > 0) {
    qString = paramObj.q;
  } else {
    qString = "";
  }

  if (fn.stringLength(paramObj.uri) > 0) {
    uri = paramObj.uri;
  } else {
    uri = "";
  }

  if (fn.stringLength(paramObj.fileId) > 0) {
    id = paramObj.fileId;
  } else {
    id = "";
  }

  if (fn.stringLength(paramObj.workPaperId) > 0) {
    workPaperId = paramObj.workPaperId;
  } else {
    workPaperId = "";
  }

  if (fn.stringLength(id) > 0) {
  
    doc = slib.getWorkpaperUri(client, id);

    xdmp.log("GR001 --- uri: " + doc.xpath("/metadataUri/text()"));

    retObj =
      {
        id: doc.xpath("/templateId/text()"),
        workPaperId: doc.xpath("/workPaperId/text()"),
        client: doc.xpath("/client/text()"),
        user: doc.xpath("/user/text()"),
        fileUri: doc.xpath("/binFileUri/text()"),
        metadataUri: doc.xpath("/metadataUri/text()")
      };

  } else if (fn.stringLength(workPaperId) > 0) {

    doc = slib.getWorkpaperUriByWorkpaperId(client, workPaperId);

    xdmp.log("GR001 --- uri: " + doc.xpath("/metadataUri/text()"));

    retObj =
      {
        id: doc.xpath("/templateId/text()"),
        workPaperId: doc.xpath("/workPaperId/text()"),
        client: doc.xpath("/client/text()"),
        user: doc.xpath("/user/text()"),
        fileUri: doc.xpath("/binFileUri/text()"),
        metadataUri: doc.xpath("/metadataUri/text()")
      };

  } else {
  
    doc = slib.getWorkpaperListByClient(client)
    
    var count = doc.xpath("/count/text()");
    var templates = doc.xpath("/template");
    
    var resultsDoc = [];
    
    var templatesDoc = templates.next().value;
        
    var idList    = templatesDoc.xpath("/template/templateId/text()").valueOf();
    var jIdList   = xdmp.toJSON(idList);
    
    var userList  = templatesDoc.xpath("/template/user/text()").valueOf();
    var jUserList = xdmp.toJSON(userList);
    
    var uriList   = templatesDoc.xpath("/template/templateUri/text()").valueOf();
    var jUriList  = xdmp.toJSON(uriList);
    
    var metaUriList = templatesDoc.xpath("/template/templateMetadataUri/text()").valueOf();
    var jMetaUriList = xdmp.toJSON(metaUriList);

    var workPaperIdList = templatesDoc.xpath("/template/workPaperId/text()").valueOf();
    var jWorkPaperIdList = xdmp.toJSON(workPaperIdList);

    for (i = 0; i < count; i++)
    {
      var tObj = templates.next().value;
      
      var obj = {
          id: jIdList.root[i],
          client: client,
          workPaperId: jWorkPaperIdList.root[i],
          user: jUserList.root[i],
          fileUri: jUriList.root[i],
          metadataUri: jMetaUriList.root[i]
      };
      
      resultsDoc.push(obj);
    }

    retObj = {
      count: count,
      results: resultsDoc
    }
  }

  return retObj;
};

/*
  (: GR001 - Get client and user id from token :)
  let $client := "ey001"
  let $user   := "janedoe"
  
  let $merge :=
    if (fn:empty(map:get($params, "merge"))) then
      ""
    else
      map:get($params, "merge")

  let $tempUri :=
    if (fn:empty(map:get($params, "uri"))) then
      ""
    else
      map:get($params, "uri")

  let $id :=
    if (fn:empty(map:get($params, "id"))) then
      ""
    else
      map:get($params, "id")

  let $uri :=
    if (fn:string-length($id) gt 0) then
      tr:getUserDataById($client, $id)/uri/text()
    else
      $tempUri

  let $log := xdmp:log("1 ----- User Workpaper Uri: "||$uri)
  let $log := xdmp:log("2 ----- User Workpaper Id:  "||$id)
 */

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

  var results = [];
  context.outputTypes = [];
  context.outputStatus = [200, 'OK'];

  var userObj = getUserInfo();

  var binDoc = normalizeInput(input);

  var fileName, returnDoc, uri, fileId, fileUri, retStatus, doc, workPaperId, version;
  var fileDir, fileMetadataDir, hashedUri, userFullName, user;

  var client = "ey001";
  fileId = "";
  
  var paramObj = getParameters(params);

  if (fn.stringLength(paramObj.workPaperId) > 0) {
    workPaperId = paramObj.workPaperId;
  } else {
    workPaperId = "";
  }
  
  if (fn.stringLength(paramObj.version) > 0) {
    version = paramObj.version;
  } else {
    version = "";
  }
  
  if (fn.stringLength(paramObj.client) > 0) {
    client = paramObj.client;
  } else {
    client = "ey001";
  }

  if (fn.stringLength(paramObj.fileName) > 0) {
    fileName = paramObj.fileName;
  } else {
    fileName = "";
  }

  if (fn.stringLength(paramObj.user) > 0) {
    userFullName = paramObj.user;
    user         = getUserIdFromUserFullName(userFullName);
  } else {
    userFullName = userObj.userFullName.valueOf();
    user         = userObj.user.valueOf();
  }

  fileDir = "/client/" + client + "/wpaper";

xdmp.log("GR001 - fileName:    " + fileName);
xdmp.log("GR001 - fileId:      " + fileId);
xdmp.log("GR001 - client:      " + client);
xdmp.log("GR001 - version:     " + version);
xdmp.log("GR001 - workPaperId: " + workPaperId);

  fileMetadataDir = fileDir + "/" + fileName;
  fileMetadataUri = fileMetadataDir + "/" + fileName + ".xml";
  binFileUri      = fileMetadataDir + "/" + fileName + ".xlsx";

  doc = ingest.extractSpreadsheetData(client, userFullName, user, version, workPaperId, binFileUri, "", binDoc);

  hashedFileUri = xdmp.hash64(fileMetadataDir + xdmp.toJSON(doc).toString());

  xdmp.log("GR001 - fileMetadataUri: " + fileMetadataUri)
  xdmp.log("GR001 - binFileUri:      " + binFileUri)
  xdmp.log("GR001 - userFullName:    " + userFullName);
  xdmp.log("GR001 - user:            " + user);
  xdmp.log("GR001 - hashedFileUri:   " + hashedFileUri)

  var evalCmd =
      'declareUpdate();\n' +
      'var metaUri, doc, uri, binDoc;\n' +
      'xdmp.documentInsert(metaUri, doc, xdmp.defaultPermissions(), ("spreadsheet"));\n' +
      'xdmp.documentInsert(uri, binDoc, xdmp.defaultPermissions(), ("binary"));';

  var evalDoc =
    xdmp.eval(
      evalCmd,
      {
        metaUri: fileMetadataUri,
        doc: doc,
        uri: binFileUri,
        binDoc: binDoc
      }
    );

  var retObj =
    {
      status: "Document Inserted Successfully",
      uri: fileMetadataUri,
      fileId: doc.xpath("/*:meta/*:templateId/text()"),
      client: client,
      user: user,
      userFullName: userFullName
    };

  return retObj;
};

function deleteFunction(context, params) {
  xdmp.log('DELETE invoked');

  var results = [];
  context.outputTypes = [];
  context.outputTypes.push('application/json');

  context.outputStatus = [201, 'OK'];

  var client = "ey001";
  var fileName, returnDoc, uri, fileId, fileUri, retStatus, doc;
  
  var paramObj = getParameters(params);

  retStatus = "document was not deleted";
  fileUri   = "";

  if (fn.stringLength(paramObj.client) > 0) {
    client = paramObj.client;
  } else {
    client = "ey001";
  }

  if (fn.stringLength(paramObj.fileName) > 0) {
    fileName = paramObj.fileName;
  } else {
    fileName = "";
  }

  if (fn.stringLength(paramObj.fileId) > 0) {
    fileId = paramObj.fileId;
  } else {
    fileId = "";
  }

xdmp.log("GR001......... fileId: " + fileId);
xdmp.log("GR001......... fileName: " + fileName);

  if (fn.stringLength(fileName) > 0) {
  
      // verify file Uri
      fileUri  = "/client/" + client + "/wpaper/" + fileName + "/"
      fileUrl = fileUri + fileName + ".xml"

      doc = cts.doc(fileUrl);
      if (doc) {
        fileId = doc.xpath("/*:workbook/*:meta/*:templateId/text()");
      }

      if (fn.stringLength(fileId) > 0) {
        xdmp.directoryDelete(fileUri);
        retStatus = "document was deleted"
      } else {
        retStatus = "document was not deleted"
      }
      
  } else if (fn.stringLength(fileId) > 0) {

      // get file Uri using fileId
      fileUrl = slib.getWorkpaperUri(client, fileId).xpath("/metadataUri/text()");

      var fileNameSections, fileDir, newFileId;
      newFileId = "";

      fileNameSections = fn.tokenize(fileUrl, "/").toArray();

      if (fileNameSections[fileNameSections.length-2]) {
      
        fileName = fileNameSections[fileNameSections.length-2];
        
        fileDir = fn.substringBefore(fileUrl, fileNameSections[fileNameSections.length-1]);
  
        doc = cts.doc(fileUrl);
        if (doc) {
          newFileId = doc.xpath("/*:workbook/*:meta/*:templateId/text()");
        }
  
        if (fn.stringLength(newFileId) > 0) {
        
          xdmp.directoryDelete(fileDir);
          retStatus = "document was deleted"
          
        }
      }
  }
  
  var retObj =
  {
    status: retStatus,
    client: client,
    fileId: fileId,
    fileName: fileName,
    fileUri: fileUri
  }
  
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

function getWorkpaperUriById(client, id)
{
  //client = "ey001";
  //id     = "3857790183476763686";
  
  binfileUri = slib.getTemplateUri(client, id).xpath("/binFileUri/text()");

  var binFileNameSections = fn.tokenize(binfileUri, "/").toArray();
  
  var uri = fn.substringBefore(binfileUri, binFileNameSections[binFileNameSections.length-1]);
  
  var retObj =
    {
      uri: uri
    };

  return retObj;
};

function getParameters(params)
{
  var fileName, fileId, client, user, merge, uri, q, workPaperId, version;
  
  for (var pname in params) {
    if (params.hasOwnProperty(pname)) {
    
      xdmp.log("GR001 - pname: " + pname + " | param: " + params[pname]);

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
      workPaperId: workPaperId
    };

  return retObj;
};

function getUserInfo()
{
  var temp, firstName, lastName, userFullName, user;
  
  var userObj = xdmp.unquote(ingest.getUserFullNameJson()).next().value;
  
  firstName = userObj.root.firstName.valueOf();
  lastName  = userObj.root.lastName.valueOf();
  
  userFullName = firstName + ' ' + lastName;
  
  user = getUserIdFromUserFullName(userFullName);
  
  var retObj =
    {
      userFullName: userFullName,
      user: user
    };

  return retObj;
};

function getUserIdFromUserFullName(fullName)
{
  var user, fullNameSections, fName, lName, text = "";
  
  fName = fn.substringBefore(fullName, " ");
  
  fullNameSections = fn.tokenize(fullName, " ").toArray();
  lName = fullNameSections[fullNameSections.length-1];
  
  for (index = 0; index < fullNameSections.length; index++) {
    text += fullNameSections[index];
  };
  text = text.replace(/\./g,'');
  text = text.replace(/\'/g,'');
  
  user = fn.lowerCase(text);
  
  return user;
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
