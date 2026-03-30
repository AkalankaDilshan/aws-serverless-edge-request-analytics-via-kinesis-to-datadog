exports.handler = (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false;
  callback(null, event.Records[0].cf.request);
};