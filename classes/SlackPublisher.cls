public with sharing class SlackPublisher {

  public class Obj {
    @InvocableVariable(label='Slack Named Credential')
    public String namedCredential;

    @InvocableVariable(label='Slack JSON Message')
    public String message;
  }

  @InvocableMethod(label='Post to Slack')
  public static void postToSlack(List<Obj> objects) {
    Obj o = objects[0]; // If bulk, only post first to avoid overloading Slack channel
    System.enqueueJob(new QueueableSlackCall('callout:' + o.namedCredential, 'POST', o.message));
  }

  public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {
        private final String url;
        private final String method;
        private final String body;

        public QueueableSlackCall(String url, String method, String body) {
            this.url = url;
            this.method = method;
            this.body = body;
        }

        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            HttpResponse res = http.send(req);
        }
    }

}