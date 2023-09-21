import ballerina/graphql;
import ballerina/log;

public type Task record {
    readonly int taskId;
    string taskName;
    int workerId;
    string taskDescription;
    Subtask[] subtasks;
};

public type Subtask record {
    string subtaskName;
    int estimatedDays;
};

table<Task> key(taskId) taskTable = table [
    {taskId: 1, taskName: "Task 1", workerId: 101, taskDescription: "Description for Task 1", subtasks: [{subtaskName: "sub11", estimatedDays: 11}]},
    {taskId: 2, taskName: "Task 2", workerId: 102, taskDescription: "Description for Task 2", subtasks: [{subtaskName: "sub1", estimatedDays: 1}]},
    {taskId: 3, taskName: "Task 3", workerId: 105, taskDescription: "Description for Task 3", subtasks: [{subtaskName: "sub32", estimatedDays: 3}]}
];

public distinct service class TaskService {
    private final readonly & Task taskRecord;

    function init(Task taskRecord) {
        self.taskRecord = taskRecord.cloneReadOnly();
    }

    resource function get taskId() returns int {
        return self.taskRecord.taskId;
    }

    resource function get workerId() returns int {
        return self.taskRecord.workerId;
    }

    resource function get taskName() returns string {
        return self.taskRecord.taskName;
    }

    resource function get taskDescription() returns string {
        return self.taskRecord.taskDescription;
    }

    resource function get subtasks() returns SubTaskService[] {
        return self.taskRecord.subtasks.map(subtask => new SubTaskService(subtask));
    }
}

public distinct service class SubTaskService {
    private final readonly & Subtask subtaskRecord;

    function init(Subtask subtaskRecord) {
        self.subtaskRecord = subtaskRecord.cloneReadOnly();
    }

    resource function get subtaskName() returns string {
        return self.subtaskRecord.subtaskName;
    }

    resource function get estimatedDays() returns int {
        return self.subtaskRecord.estimatedDays;
    }
}

@display {
    label: "user-management-service",
    id: "user-management-service-9cd8d434-cc1f-4755-affb-fdf5b75ecd91"
}
service /tasks on new graphql:Listener(9000) {
    resource function get allTasks() returns TaskService[] {
        Task[] tasks = taskTable.toArray().cloneReadOnly();
        log:printInfo("All tasks: " + tasks.toString());
        return tasks.map(task => new TaskService(task));
    }

    resource function get tasksByWorkerId(int workerId) returns TaskService[] {
        Task[] tasks = taskTable.toArray().cloneReadOnly();
        Task[] workerTasks = tasks.filter(task => task.workerId == workerId);
        return workerTasks.map(task => new TaskService(task));
    }

    remote function addTask(Task task) returns TaskService {
        taskTable.add(task);
        return new TaskService(task);
    }
}
