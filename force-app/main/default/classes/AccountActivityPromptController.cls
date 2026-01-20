public with sharing class AccountActivityPromptController {
    
        @InvocableMethod(label='Prepare Account Activity Data for AI')
        public static List<Response> getActivityPrompt(List<Request> requests) {
    
            List<Response> responses = new List<Response>();
    
            for (Request req : requests) {
                Response res = new Response();
                responses.add(res);
                 Id accountId = req.RelatedEntity.Id;
                
                Date last30Days = Date.today().addDays(-30);
    
            List<Task> tasks = [
                SELECT Subject, Status, ActivityDate, IsClosed
                FROM Task
                WHERE WhatId = :accountId
                AND ActivityDate >= :last30Days
                ORDER BY ActivityDate DESC
            ];
    
            Integer overdueTasks = 0;
            List<String> recentTasks = new List<String>();
    
            for (Task t : tasks) {
                if (!t.IsClosed && t.ActivityDate < Date.today()) {
                    overdueTasks++;
                }
                if (t.IsClosed && recentTasks.size() < 5) {
                    recentTasks.add(t.Subject + ' – Completed');
                }
            }
    
            List<Event> events = [
                SELECT Subject, ActivityDate
                FROM Event
                WHERE WhatId = :accountId
                AND ActivityDate >= :last30Days
                ORDER BY ActivityDate ASC
            ];
    
            List<String> upcomingMeetings = new List<String>();
            for (Event e : events) {
                if (e.ActivityDate >= Date.today() && upcomingMeetings.size() < 3) {
                    upcomingMeetings.add(e.Subject);
                }
            }
    
            Map<String, Object> output = new Map<String, Object>{
                'TotalActivitiesLast30Days' => tasks.size() + events.size(),
                'OverdueTasks' => overdueTasks,
                'LastActivityDate' => tasks.isEmpty() ? null : tasks[0].ActivityDate.format(),
                'RecentTasks' => recentTasks,
                'UpcomingMeetings' => upcomingMeetings
            };
            res.Prompt = JSON.serializePretty(output);
            responses.add(res);
            }
    
            return responses;
        }
    

    
        public class Request {
            @InvocableVariable(required=true)
            public account RelatedEntity ;
        }
    
        public class Response {
            @InvocableVariable
            public String Prompt;
        }
    }