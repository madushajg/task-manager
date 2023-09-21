import ballerina/graphql;
import ballerina/http;
import ballerina/log;
import ballerinax/twilio;
import ballerinax/twitter;

service / on new http:Listener(9090) {
    @display {
        label: "Twilio Client",
        id: "twilio-365540bb-7f7f-4423-920a-6c6c487fdffe"
    }
    twilio:Client twilioEp;

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
        self.twilioEp = check new (config = {
            twilioAuth: {
                accountSId: "",
                authToken: ""
            }
        });
        self.twitterEp = check new (config = {
            apiKey: "",
            apiSecret: "",
            accessToken: "",
            accessTokenSecret: ""
        });
        self.userManagementServiceClient = check new ("localhost:9000/tasks");
    }

    resource function get taskByUserId(int userId) returns Task[]|error {
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
        TaskDTO[] taskDTO = transform(x.data.allTasks);
        boolean hasUnfinishedTasks = x.data.allTasks.some(task => !task.isCompleted);
        if (!hasUnfinishedTasks) {
            twitter:Tweet _ = check self.twitterEp->tweet(tweetText = "Ready to ship");
        }
        return taskDTO;
    }

    resource function post addNewTask(Task payload) returns http:Created|error {
        string document = string `mutation ($task:Task!) { addTask(task: $task) {taskId} }`;
        record {|anydata...;|}|error res = self.userManagementServiceClient->execute(document, {task: {...payload}});
        if (!(res is error)) {
            twilio:SmsResponse _ = check self.twilioEp->sendSms(fromNo = "", toNo = "", message = "New task added");
        }
        return {};
    }

    resource function put changeOwnership(string userId, string taskId) returns http:Ok {
        return {};
    }
}

type TasksByWorkerResponse record {|
    record {|Task[] tasksByWorkerId;|} data;
|};

type AllTasksResponse record {|
    record {|Task[] allTasks;|} data;
|};

public type Task record {
    int taskId;
    string taskName;
    int workerId;
    string taskDescription;
    boolean isCompleted;
    string[] subtasks;
};

public type TaskDTO record {
    string id;
    int workerId;
    string description;
    string subtasks;
};

function transform(Task[] task) returns TaskDTO[] => from var taskItem in task
    select {
        id: taskItem.taskId.toString(),
        workerId: taskItem.workerId,
        subtasks: string:'join(",", ...taskItem.subtasks),
        description: (taskItem.isCompleted ? "" : "WIP") + taskItem.taskDescription
    };
