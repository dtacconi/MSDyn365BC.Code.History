#if not CLEAN18
codeunit 135531 "Dimensions E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Dimension]
    end;

    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'dimensions';
        SubpageServiceNameTxt: Label 'dimensionValues';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDimensions()
    var
        Dimension: Record Dimension;
        DimensionCode: array[2] of Text;
        DimensionJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Use a GET method to retrieve the dimensions
        // [GIVEN] 2 dimensions in the table
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[1] := Dimension.Code;
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[2] := Dimension.Code;
        Commit();

        // [WHEN] we GET all the dimensions from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimensions Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 dimensions should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, DimensionCode[1], DimensionJSON[1]);
        GetAndVerifyIDFromJSON(ResponseText, DimensionCode[2], DimensionJSON[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDimensionValues()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueCode: array[2] of Text;
        DimensionValueJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Use a GET method to retrieve the dimension values
        // [GIVEN] 2 dimension value codes of a specific dimension
        Initialize();
        LibraryDimension.CreateDimension(Dimension);

        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[1] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[2] := DimensionValue.Code;
        Commit();

        // [WHEN] we GET all the dimension values from the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(Dimension.SystemId, PAGE::"Dimensions Entity", ServiceNameTxt, SubpageServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 dimension values should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, DimensionValueCode[1], DimensionValueJSON[1]);
        GetAndVerifyIDFromJSON(ResponseText, DimensionValueCode[2], DimensionValueJSON[2]);
    end;

    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; DimensionCode: Text; var DimensionJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', DimensionCode, DimensionCode, DimensionJSON, DimensionJSON),
          'Could not find the dimension in JSON');
        LibraryGraphMgt.VerifyIDInJson(DimensionJSON);
    end;
}
#endif
