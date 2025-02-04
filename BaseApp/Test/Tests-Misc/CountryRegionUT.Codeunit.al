codeunit 134277 "Country/Region UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Country/Region]
    end;

    var
        Assert: Codeunit Assert;
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [Scope('OnPrem')]
    procedure T100_ISOCodeIs2ASCIIChars()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Code" can be blank or must contain 2 ASCII letters
        asserterror CountryRegion.Validate("ISO Code", CopyStr('EUR', 1, 3));
        Assert.ExpectedError('is 3, but it must be less than or equal to 2 characters');

        asserterror CountryRegion.Validate("ISO Code", 'E');
        Assert.ExpectedError('is 1, but it must be equal to 2 characters');

        asserterror CountryRegion.Validate("ISO Code", 'E1');
        Assert.ExpectedError(ASCIILetterErr);

        CountryRegion.Validate("ISO Code", 'eU');
        CountryRegion.TestField("ISO Code", 'EU');

        CountryRegion.Validate("ISO Code", '');
        CountryRegion.TestField("ISO Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_ISONumericCodeIs3Numbers()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Numeric Code" can be blank or must contain 2 ASCII letters
        asserterror CountryRegion.Validate("ISO Numeric Code", CopyStr('1234', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror CountryRegion.Validate("ISO Numeric Code", '01');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror CountryRegion.Validate("ISO Numeric Code", 'EU1');
        Assert.ExpectedError(NumericErr);

        CountryRegion.Validate("ISO Numeric Code", '001');
        CountryRegion.TestField("ISO Numeric Code", '001');

        CountryRegion.Validate("ISO Numeric Code", '');
        CountryRegion.TestField("ISO Numeric Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ISOCodesEditableInCountryList()
    var
        CountryRegion: Record "Country/Region";
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Countries\Regions page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'XX', where "ISO Code" is 'YY', "ISO Numeric Code" is '001'
        CountryRegion.Init();
        CountryRegion.Code := 'XX';
        CountryRegion."ISO Code" := 'YY';
        CountryRegion."ISO Numeric Code" := '001';
        CountryRegion.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        CountriesRegions.OpenEdit;
        CountriesRegions.FILTER.SetFilter(Code, 'XX');
        Assert.IsTrue(CountriesRegions."ISO Code".Editable, 'ISO Code.EDITABLE');
        Assert.IsTrue(CountriesRegions."ISO Numeric Code".Editable, 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        CountriesRegions."ISO Code".SetValue('ZZ');
        CountriesRegions."ISO Numeric Code".SetValue('999');
        CountriesRegions.Close;

        // [THEN] Country 'XX', where "ISO Code" is 'ZZ', "ISO Numeric Code" is '999'
        CountryRegion.Find;
        CountryRegion.TestField("ISO Code", 'ZZ');
        CountryRegion.TestField("ISO Numeric Code", '999');
    end;
}

