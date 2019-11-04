@IsTest
private class SlackPublisherTest {
    @IsTest
    static void postToSlackTest() {
        Test.setMock(HttpCalloutMock.class, new SlackPublisherCalloutMockImpl());

        SlackPublisher.Obj o = new SlackPublisher.Obj();
        o.namedCredential = 'hey';
        o.message = 'hey';

        Test.startTest();
        SlackPublisher.postToSlack(new List<SlackPublisher.Obj>{ o });
        Test.stopTest();
    }

    public class SlackPublisherCalloutMockImpl implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            return new HttpResponse();
        }
    }
}