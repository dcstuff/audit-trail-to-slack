@IsTest(SeeAllData=true)
class SchedulableAuditTrailPosterTest {
    @IsTest
    static void methodName() {
        Test.setMock(HttpCalloutMock.class, MockHttpResponse.builder()
            .contentType('application/json')
            .body('{ "status": "OK" }')
        );

        Test.startTest();
        SchedulableAuditTrailPoster.runEvery(5);
        Test.stopTest();
    }
}