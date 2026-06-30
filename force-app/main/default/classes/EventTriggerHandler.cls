public with sharing class EventTriggerHandler extends TriggerHandler {
    private static final String OVERLAPPING_EVENT_ERROR = 'You already have an interview at this time.';
    private static final String TOO_MANY_EVENTS_ERROR = 'There are too many existing events in this time range to safely check for overlaps. Please narrow the event time range and try again.';
    private static final Integer MAX_OVERLAPPING_EVENTS = 10000;

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
        List<Event> eventsToCheck = new List<Event>();
        // Using Sets because we don't want to have any dupes
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> eventIdsToExcludeFromQuery = new Set<Id>();
        Datetime earliestStartDateTime;
        Datetime latestEndDateTime;

        // Collect the owners and carve down to the smallest possible time window we need to check
        for (Event newEvent : newEventList) {
            if (newEvent.StartDateTime == null || newEvent.EndDateTime == null) {
                continue;
            }

            eventsToCheck.add(newEvent);
            ownerIds.add(getOwnerId(newEvent));

            // We are excluding each event itself from the query - oterwise, it'll trigger a false overlap when updating
            if (newEvent.Id != null) {
                eventIdsToExcludeFromQuery.add(newEvent.Id);
            }

            if (earliestStartDateTime == null || newEvent.StartDateTime < earliestStartDateTime) {
                earliestStartDateTime = newEvent.StartDateTime;
            }

            if (latestEndDateTime == null || newEvent.EndDateTime > latestEndDateTime) {
                latestEndDateTime = newEvent.EndDateTime;
            }
        }

        if (eventsToCheck.isEmpty()) {
            return;
        }

        checkForOverlapsInThisSave(eventsToCheck);

        Integer possibleOverlapCount;

        // Count first so we don't try to blow past 10K limit per transaction
        // two conditions because we need to handle update differently (else condition has extra exclusion in query)
        if (eventIdsToExcludeFromQuery.isEmpty()) {
            possibleOverlapCount = [
                SELECT COUNT()
                FROM Event
                WHERE OwnerId IN :ownerIds
                AND StartDateTime < :latestEndDateTime
                AND EndDateTime > :earliestStartDateTime
            ];
        } else {
            possibleOverlapCount = [
                SELECT COUNT()
                FROM Event
                WHERE OwnerId IN :ownerIds
                AND StartDateTime < :latestEndDateTime
                AND EndDateTime > :earliestStartDateTime
                AND Id NOT IN :eventIdsToExcludeFromQuery
            ];
        }

        if (possibleOverlapCount >= MAX_OVERLAPPING_EVENTS) {
            for (Event newEvent : eventsToCheck) {
                newEvent.addError(TOO_MANY_EVENTS_ERROR);
            }
            return;
        }

        List<Event> existingEvents;

        // Now it's a much smaller band but now we need to deal with Owner
        if (eventIdsToExcludeFromQuery.isEmpty()) {
            existingEvents = [
                SELECT Id, OwnerId, StartDateTime, EndDateTime
                FROM Event
                WHERE OwnerId IN :ownerIds
                AND StartDateTime < :latestEndDateTime
                AND EndDateTime > :earliestStartDateTime
                ORDER BY OwnerId, StartDateTime
            ];
        } else {
            existingEvents = [
                SELECT Id, OwnerId, StartDateTime, EndDateTime
                FROM Event
                WHERE OwnerId IN :ownerIds
                AND StartDateTime < :latestEndDateTime
                AND EndDateTime > :earliestStartDateTime
                AND Id NOT IN :eventIdsToExcludeFromQuery
                ORDER BY OwnerId, StartDateTime
            ];
        }

        Map<Id, List<Event>> existingEventsByOwnerId = new Map<Id, List<Event>>();

        for (Event existingEvent : existingEvents) {
            if (existingEventsByOwnerId.containsKey(existingEvent.OwnerId) == false) {
                existingEventsByOwnerId.put(existingEvent.OwnerId, new List<Event>());
            }

            existingEventsByOwnerId.get(existingEvent.OwnerId).add(existingEvent);
        }

        for (Event newEvent : eventsToCheck) {
            List<Event> eventsForThisOwner = existingEventsByOwnerId.get(getOwnerId(newEvent));

            if (eventsForThisOwner == null) {
                continue;
            }

            for (Event existingEvent : eventsForThisOwner) {
                if (newEvent.StartDateTime < existingEvent.EndDateTime
                    && newEvent.EndDateTime > existingEvent.StartDateTime) {
                    newEvent.addError(OVERLAPPING_EVENT_ERROR);
                    // If we find overlap, DML transaction is blocked by error, so no need to keep going through inner loop
                    break;
                }
            }
        }
    }

    private static void checkForOverlapsInThisSave(List<Event> eventsToCheck) {
        // using i and j to iterate index 0 and 1, then 1 and 2, etc. so all events are compared without duplicative checks
        for (Integer i = 0; i < eventsToCheck.size(); i++) {
            Event firstEvent = eventsToCheck[i];
            Id firstOwnerId = getOwnerId(firstEvent);

            for (Integer j = i + 1; j < eventsToCheck.size(); j++) {
                Event secondEvent = eventsToCheck[j];
                Id secondOwnerId = getOwnerId(secondEvent);

                if (firstOwnerId == secondOwnerId
                    && firstEvent.StartDateTime < secondEvent.EndDateTime
                    && firstEvent.EndDateTime > secondEvent.StartDateTime) {
                    firstEvent.addError(OVERLAPPING_EVENT_ERROR);
                    secondEvent.addError(OVERLAPPING_EVENT_ERROR);
                }
            }
        }
    }

    private static Id getOwnerId(Event eventRecord) {
        if (eventRecord.OwnerId == null) {
            return UserInfo.getUserId();
        }

        return eventRecord.OwnerId;
    }
}
