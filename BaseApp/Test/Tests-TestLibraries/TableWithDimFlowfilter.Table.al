table 134484 "Table With Dim Flowfilter"
{

#if not CLEAN20
    LookupPageID = "XBRL Taxonomy Lines";
#endif

    fields
    {
        field(1; Name; Code[20])
        {
            NotBlank = true;
#if not CLEAN20
            TableRelation = "XBRL Taxonomy";
#endif
        }
        field(16; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(17; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
