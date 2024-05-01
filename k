var PAYMENT_METHOD_TYPE_CARD = "クレジットカード決済";
var PAYMENT_METHOD_TYPE_BANK = "銀行振込";
var FORM_ID = "formのID";
var ITEM_NAME_PAYMENT_METHOD = "支払い方法";
var ITEM_NAME_IS_PAID = "支払い済み";

function onFormSubmit(e) {
  //var e.response = FormApp.getActiveForm().createResponse();
  var form = e.source;
  //var form = FormApp.openById(id);

  var email = e.response.getRespondentEmail();

  var paymentMethodItem = getItemsByTitle(form, ITEM_NAME_PAYMENT_METHOD)[0];
  var paymentMethodResponse = e.response.getResponseForItem(paymentMethodItem);
  if (PAYMENT_METHOD_TYPE_CARD === paymentMethodResponse.getResponse()) {
    var doGetUrl = ScriptApp.getService().getUrl();
    if (doGetUrl.indexOf("?") >= 0) {
      doGetUrl = doGetUrl + "&responseId=" + e.response.getId();
    } else {
      doGetUrl = doGetUrl + "?responseId=" + e.response.getId();
    }
    MailApp.sendEmail(email, "金払え", doGetUrl);    
  } else {
    MailApp.sendEmail(email, "金払え", "ここに振り込んでください。 ~~~~");
  }
}

function getItemsByTitle(form, title) {

  return form.getItems().filter(function(item) {
    //var item = form.getItemById();
    Logger.log(item.getTitle());
    return item.getTitle() === title;
  });
}


function doGet(e) {
  var responseId = e.parameter.responseId;

  if (!responseId || responseId === "") {
    return HtmlService.createHtmlOutput("エラーだよ");
  }

  var form = FormApp.openById(FORM_ID);
  var response = form.getResponse(responseId);
  var paymentMethodItem = getItemsByTitle(form, ITEM_NAME_PAYMENT_METHOD)[0];
  var paymentMethodResponse = response.getResponseForItem(paymentMethodItem);
  if (PAYMENT_METHOD_TYPE_CARD !== paymentMethodResponse.getResponse()) {
    return HtmlService.createHtmlOutput("銀行振込してください。");
  }

  var stripePublishableKey = PropertiesService.getScriptProperties().getProperty("stripePublishableKey");

  var template = HtmlService.createTemplateFromFile("stripe.html");
  template.url = ScriptApp.getService().getUrl();
  template.stripePublishableKey = stripePublishableKey;
  template.responseId = responseId;
  return template.evaluate();
}

function doPost(e) {
  var stripeToken = e.parameter.stripeToken;
  var responseId = e.parameter.responseId;
  var stripeEmail = e.parameter.stripeEmail;
  var form = FormApp.openById(FORM_ID);
  var response = form.getResponse(responseId);
  var result = UrlFetchApp.fetch("https://api.stripe.com/v1/charges", {
    'method' : 'post',
    'payload' : {
      'amount': "1000",
      'currency': 'jpy',
      'description': 'Charge',
      'source': stripeToken
    },


<html>
  <head>
    <base target="_top">
    <script type="text/javascript" src="https://js.stripe.com/v3/"></script>
  </head>
  <body>
  <form action="<?= url ?>" method="POST">
  <script
    src="https://checkout.stripe.com/checkout.js" class="stripe-button"
    data-key="<?= stripePublishableKey?>"
    data-amount="1000"
    data-currency='jpy'
    data-name="決済するよ"
    data-description="決済"
    data-image="https://stripe.com/img/documentation/checkout/marketplace.png"
    data-locale="auto">
  </script>
  <input type="hidden" name="responseId" value="<?= responseId?>">
  </form>
  </body>
</html>
    'headers' : {'Authorization' : " Basic " + Utilities.base64Encode(PropertiesService.getScriptProperties().getProperty("stripePrivateKey") + ':')}
  });

  return HtmlService.createHtmlOutput("決済が完了しました。");
}
