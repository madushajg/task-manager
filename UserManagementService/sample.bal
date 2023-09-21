import ballerina/graphql;
import ballerina/log;

public type Task record {
    readonly int taskId;
    string taskName;
    int workerId;
    string taskDescription;
    boolean isCompleted;
    string[] subtasks;
};

table<Task> key(taskId) taskTable = table [
    {taskId: 1, taskName: "Task 1", workerId: 101, taskDescription: "Description for Task 1", isCompleted: false, subtasks: ["st1"]},
    {taskId: 2, taskName: "Task 2", workerId: 102, taskDescription: "Description for Task 2", isCompleted: true, subtasks: ["st1, st2"]},
    {taskId: 3, taskName: "Task 3", workerId: 105, taskDescription: "Description for Task 3", isCompleted: false, subtasks: ["st3"]}
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

    resource function get isCompleted() returns boolean {
        return self.taskRecord.isCompleted;
    }

    resource function get subtasks() returns string[] {
        return self.taskRecord.subtasks;
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
        log:printInfo("Adding task: " + task.toString());
        taskTable.add(task);
        log:printInfo("Task added: " + task.toString());
        return new TaskService(task);
    }
}
