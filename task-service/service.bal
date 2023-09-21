import ballerina/graphql;
import ballerina/http;
import ballerina/log;
import ballerinax/twitter;

service / on new http:Listener(9090) {
    @display {
        label: "Twitter",
        id: "twitter-54f2c679-9c92-41fc-8f76-e93513b2dbe6"
    }
    twitter:Client twitterEp;

    @display {
        label: "user-management-service",
        id: "user-management-service-9cd8d434-cc1f-4755-affb-fdf5b75ecd91"
    }
    graphql:Client userManagementServiceClient;

    function init() returns error? {
        self.twitterEp = check new (config = {
            apiKey: "",
            apiSecret: "",
            accessToken: "",
            accessTokenSecret: ""
        });
        self.userManagementServiceClient = check new ("localhost:9000/tasks");
    }

    resource function get userTasks(int userId) returns Task[]|error {
        if userId <= 0 {
            return error("Invalid userId!");
        }
        string document = string `{ tasksByWorkerId(workerId: ${userId}) { taskId, taskName } }`;
        TasksByWorkerResponse x = check self.userManagementServiceClient->execute(document);
        log:printInfo("Response from user-management-service: " + x.toString());
        return x.data.tasksByWorkerId;
    }

    resource function get allTasks() returns TaskDTO[]|error {
        string document = "{ allTasks { taskId, subtasks { subtaskName, estimatedDays } } }";
        AllTasksResponse x = check self.userManagementServiceClient->execute(document);
        twitter:Tweet _ = check self.twitterEp->tweet(tweetText = "");
        return transform(x.data.allTasks);
    }
}

type TasksByWorkerResponse record {|
    record {|Task[] tasksByWorkerId;|} data;
|};

type AllTasksResponse record {|
    record {|Task[] allTasks;|} data;
|};

public type Task record {
    int taskId?;
    string taskName?;
    int workerId?;
    string taskDescription?;
    Subtask[] subtasks;
};

public type Subtask record {
    string subtaskName;
    int estimatedDays;
};

public type TaskDTO record {
    string id;
    int workerId;
    int estimatedDays;
    string[] subtasks;
};

function transform(Task[] task) returns TaskDTO[] => from var taskItem in task
    select {
        id: taskItem.taskId.toString(),
        workerId: taskItem.workerId ?: 0,
        estimatedDays: taskItem.subtasks.reduce(function(int t, Subtask s) returns int => t + s.estimatedDays, 0),
        subtasks: from var subtasksItem in taskItem.subtasks
            select subtasksItem.subtaskName
    };
    