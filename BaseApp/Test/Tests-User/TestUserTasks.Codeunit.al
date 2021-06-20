﻿codeunit 134769 "Test User Tasks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User Tasks]
        Init;
    end;

    var
        User1: Record User;
        User2: Record User;
        UserTaskGroup1: Record "User Task Group";
        UserTaskGroupMember: Record "User Task Group Member";
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure TestUserCard()
    var
        UserTaskCard: TestPage "User Task Card";
        BaseDate: DateTime;
    begin
        // [SCENARIO] Test the User Task Card page.

        // [GIVEN] The User Tasks Card page.
        // [WHEN] The Page opens.
        // [THEN] Various fields are defaulted.
        BaseDate := CreateDateTime(20121212D, 000000T);
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard.Title.Value('Task 1');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime, 'Start DateTime should be 0DT');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Created DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Created DateTime');
        Assert.AreEqual('', UserTaskCard.MultiLineTextControl.Value, 'Unexpected value in the Task Description');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('5');

        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Start DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Start DateTime');

        // [WHEN] The Percent Completed field is updated to be = 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('100');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Completed DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('15');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime, 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be 0
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('0');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime, 'Unexpected Completed DateTime');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime, 'Unexpected Start Date Time');

        // [WHEN] The Completed Date field is updated.
        // [THEN] Various fields are defaulted.
        UserTaskCard."Completed DateTime".Value(Format(CurrentDateTime));
        Assert.AreEqual(100, UserTaskCard."Percent Complete".AsInteger, 'Unexpected Percent Complete');

        // [WHEN] The user creates a hyper link using the object selection controls.

        // [WHEN] The user tries to creates a hyper link using page of type card.
        // [THEN] An error message is raised, handler below.
        UserTaskCard."Object Type".Value('Page');
        asserterror UserTaskCard."Object ID".Value('21');

        UserTaskCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('UserTaskRecurrenceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestUserCardRecurrence()
    var
        UserTask: Record "User Task";
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Test the User Task Card page and add make it a recurring task.

        // [GIVEN] The User Tasks Card page.
        // [WHEN] The Page opens.
        // [THEN] Invoke the recurrence action and generate the recurring tasks.
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard.Title.Value('Task 1');
        Assert.AreEqual('Task 1', UserTaskCard.Title.Value, 'Unexpected Title');
        UserTaskCard.Recurrence.Invoke;
        Assert.AreEqual(4, UserTask.Count, 'Unexpected number of recurring tasks');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestUserPurge()
    var
        UserTask: Record "User Task";
    begin
        // [SCENARIO] Test the User Task purge.

        // [GIVEN] Several Task records with different creators.
        UserTask.DeleteAll;
        UserTask.Init;
        UserTask."Created By" := User1."User Security ID";
        UserTask."Assigned To" := User2."User Security ID";
        UserTask.Insert;

        Clear(UserTask);
        UserTask.Init;
        UserTask."Created By" := User2."User Security ID";
        UserTask."Assigned To" := User1."User Security ID";
        UserTask.Insert;

        // [WHEN] The task purge is asked to delete tasks for User1
        // [THEN] Those records are deleted, tasks created by User2 remain.

        Assert.AreEqual(2, UserTask.Count, 'Unexpected record count prior to purge');
        Commit;

        REPORT.Run(REPORT::"User Task Utility");

        Assert.AreEqual(1, UserTask.Count, 'Unexpected record count prior to purge');
        Assert.IsTrue(UserTask.FindFirst, 'Expected record to be found');
        Assert.AreEqual(User2."User Security ID", UserTask."Created By", 'Expected Task for User2 not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WinEncodingInDescriptionBLOB()
    var
        UserTask: Record "User Task";
        UserTask2: Record "User Task";
    begin
        // FEATURE] [UT]
        // [SCENARIO 253612] Task Description field in User Task table must be set accordingly to its encoding
        UserTask.Init;
        UserTask.SetDescription('Vytvorení úcetního období pro rok 2018');
        UserTask.Insert;

        UserTask2.Get(UserTask.ID);
        Assert.AreEqual('Vytvorení úcetního období pro rok 2018', UserTask2.GetDescription, 'Unexpected value in the Task Description');
    end;

    [Scope('OnPrem')]
    procedure Init()
    var
        UserTask: Record "User Task";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        UserTask.DeleteAll;

        LibraryPermissions.CreateUser(User1, '', false);
        LibraryPermissions.CreateUser(User2, '', false);

        // Create user task groups
        CreateUserTaskGroup(UserTaskGroup1);
        AddUserToUserTaskGroupByCode(User1."User Security ID", 'GroupA');
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure EnsurePageLinkedToTaskCanBeOpened()
    var
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Ensure linked page to user task card page can be opened by an action on the page.

        // [GIVEN] A task user card page with a valid page type associated with it.
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard."Object Type".Value('page');
        UserTaskCard."Object ID".Value('22');

        // [WHEN] An action on the user card page is clicked to open up linked page to task
        // [THEN] Linked page opens up handled by CustomerListPageHandler
        UserTaskCard."Go To Task Item".Invoke;

        UserTaskCard.OK.Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureUserTaskCanBeAssignedToUserTaskGroup()
    var
        UserTask: Record "User Task";
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Ensure a user task can be assigned to user task group

        // [GIVEN] Creating a new user task.
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard.Title.Value := 'Test User Task';
        UserTaskCard."User Task Group Assigned To".Value(UserTaskGroup1.Code);

        // [WHEN] user task card page is closed
        UserTaskCard.OK.Invoke;

        // [THEN] Find User task created and verify that group code is assigned
        UserTask.SetFilter(Title, 'Test User Task');
        UserTask.FindFirst;
        Assert.AreEqual(UserTaskGroup1.Code, UserTask."User Task Group Assigned To", 'Group code was not assigned to user task.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: Page "Customer List")
    begin
        // Handles customer list page opening from user task card.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var UserTaskPurge: TestRequestPage "User Task Utility")
    begin
        UserTaskPurge."User Task".SetFilter("Created By", User1."User Security ID");
        UserTaskPurge.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserTaskRecurrenceModalPageHandler(var UserTaskRecurrence: TestPage "User Task Recurrence")
    var
        DateFormulaVar: DateFormula;
    begin
        UserTaskRecurrence.RecurringStartDate.SetValue(DT2Date(CurrentDateTime));
        Evaluate(DateFormulaVar, '<1D>');
        UserTaskRecurrence.Recurrence.SetValue(DateFormulaVar);
        UserTaskRecurrence.Occurrences.SetValue(4);
        UserTaskRecurrence.OK.Invoke;
    end;

    [Scope('OnPrem')]
    procedure CreateUserTaskGroup(var UserTaskGroup: Record "User Task Group")
    begin
        UserTaskGroup.Init;
        UserTaskGroup.Code := 'Group 1';
        UserTaskGroup.Description := 'Description';
        UserTaskGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddUserToUserTaskGroupByCode(UserSecID: Guid; GroupCode: Code[20])
    begin
        if UserTaskGroupMember.Get(GroupCode, UserSecID) then
            exit;
        UserTaskGroupMember.Init;
        UserTaskGroupMember."User Task Group Code" := GroupCode;
        UserTaskGroupMember."User Security ID" := UserSecID;
        UserTaskGroupMember.Insert(true);
    end;
}

