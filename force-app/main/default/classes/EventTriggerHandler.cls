public with sharing class EventTriggerHandler extends TriggerHandler {
    private List<Event> newEventList;

    public EventTriggerHandler() {
        this.newEventList = (List<Event>) Trigger.new;
    }

    public override void beforeInsert() {
        checkForOverlappingEvents(newEventList);
    }

    public override void beforeUpdate() {
        checkForOverlappingEvents(newEventList);
    }

    public static void checkForOverlappingEvents(List<Event> newEventList) {
        Set<Datetime> futureStartDateTimes = getFutureStartDateTimes();

        if (futureStartDateTimes.isEmpty()) {
            return;
        }

        for (Event event : newEventList) {
            if (futureStartDateTimes.contains(event.StartDateTime) == true) {
                event.addError('You already have an interview at this time.');
            }
        }
    }

    private static Set<Datetime> getFutureStartDateTimes() {
        Set<Datetime> futureStartDateTimes = new Set<Datetime>();
        Datetime now = Datetime.now();
        List<Event> futureEvents = [
            SELECT Id, StartDateTime 
            FROM Event 
            WHERE StartDateTime > :now
        ];

        for (Event event : futureEvents) {
            futureStartDateTimes.add(event.StartDateTime);
        }

        return futureStartDateTimes;
    }
}
