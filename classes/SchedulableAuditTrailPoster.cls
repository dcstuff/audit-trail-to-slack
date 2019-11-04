public class SchedulableAuditTrailPoster implements Schedulable {
    public static Id runEvery(Integer minutesFromNow) {
        Datetime xMinutesFromNow = System.now().addMinutes(minutesFromNow);
        Integer seconds = xMinutesFromNow.second();
        Integer minutes = xMinutesFromNow.minute();
        Integer hour = xMinutesFromNow.hour();
        String cron = seconds + ' ' + minutes + ' ' + hour + ' * * ?';

        return System.schedule('SchedulableAuditTrailPoster - ' + System.now().getTime(), cron, new SchedulableAuditTrailPoster(minutesFromNow));
    }

    Integer minutes;

    SchedulableAuditTrailPoster(Integer minutes) {
        this.minutes = minutes;
    }

    public void execute(System.SchedulableContext sc) {
        System.abortJob(sc.getTriggerId());

        AuditTrailActionSettings__c settings = AuditTrailActionSettings__c.getOrgDefaults();
        DateTime previousFireTime = Test.isRunningTest() ? null : settings.PreviousFireTime__c;

        List<String> actions = new List<String>();
        for (AuditTrailAction__mdt action : [SELECT MasterLabel FROM AuditTrailAction__mdt]) {
            actions.add(action.MasterLabel);
        }

        if (!actions.isEmpty()) {
            String q = 'SELECT Action, DelegateUser, Display, CreatedBy.Name, CreatedDate, Section '
            + 'FROM SetupAuditTrail '
            + 'WHERE Action IN :actions '
            + 'AND CreatedDate >= ' + (previousFireTime == null ? 'TODAY' : ':previousFireTime')
            + ' ORDER BY CreatedDate DESC';

            List<SetupAuditTrail> trail = Database.query(q);

            if (!trail.isEmpty()) {
                String entries = '';
                for (Integer i = 0; i != trail.size(); i++) {
                    entries += '*_WHO:_* ' + trail[i].CreatedBy.Name + '\n';
                    entries += '*_WHAT:_* ' + (String.isBlank(trail[i].Section) ? '' : trail[i].Section + ' > ') + trail[i].Display + '\n';
                    entries += '*_WHEN:_* ' + trail[i].CreatedDate.format() + '\n';

                    if (i != trail.size() - 1) {
                        entries += ' • • •\n\n';
                    }
                }

                // escape double quotes
                entries = entries.replace('\"','\\"');

                String body = '{'+
                    +'"mrkdwn": true,'
                    +'"text": "' + entries + '"'
                +'}';

                SlackPublisher.Obj o = new SlackPublisher.Obj();
                o.message = body;
                o.namedCredential = 'SetupAuditTrailToSlack';
                SlackPublisher.postToSlack(new List<SlackPublisher.Obj>{ o });
            }
        }

        settings.PreviousFireTime__c = System.now();
        upsert settings;

        runEvery(minutes);
    }
}