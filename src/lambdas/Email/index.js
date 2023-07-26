var AWS = require('aws-sdk');
var ses = new AWS.SES();

exports.handler = (event, context, callback) => {
  console.log('Event', event);
  console.log(
    'Event Request User Attributes',
    event.request.userAttributes.email
  );
  console.log('Event Request Code Parameters', event.request.codeParameter);

  var eParams = {
    Destination: {
      ToAddresses: [event.request.userAttributes.email],
    },
    Message: {
      Body: {
        Html: {
          Charset: 'UTF-8',
          Data: `<a href='https://gatiko-confirm-email.s3.amazonaws.com/gatiko.html?email=${event.request.userAttributes.email}&confirmationCode=${event.request.codeParameter}'>Click here to verify your account</a>`,
        },
      },
      Subject: {
        Data: 'Verify Your Account',
      },
    },
    Source: 'angel@origyn.ch',
  };

  ses.sendEmail(eParams, function (err, data) {
    if (err) {
      console.log(err);
      callback(err);
    } else {
      console.log('===EMAIL SENT===');
      console.log(data);
      callback(null, event);
    }
  });

  callback(null, event);
};
