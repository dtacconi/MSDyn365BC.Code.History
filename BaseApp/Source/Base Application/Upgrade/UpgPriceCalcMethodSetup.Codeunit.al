#if not CLEAN19
codeunit 104015 "Upg Price Calc. Method Setup"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        SetPriceCalcMethodInSetup();
    end;

    local procedure SetPriceCalcMethodInSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceCalcMethodInSetupTag()) THEN
            EXIT;

        if SalesReceivablesSetup.Get() then
            if SalesReceivablesSetup."Price Calculation Method" = SalesReceivablesSetup."Price Calculation Method"::" " then begin
                SalesReceivablesSetup."Price Calculation Method" :=
                    SalesReceivablesSetup."Price Calculation Method"::"Lowest Price";
                SalesReceivablesSetup.Modify();
            end;

        if PurchasesPayablesSetup.Get() then
            if PurchasesPayablesSetup."Price Calculation Method" = PurchasesPayablesSetup."Price Calculation Method"::" " then begin
                PurchasesPayablesSetup."Price Calculation Method" :=
                    PurchasesPayablesSetup."Price Calculation Method"::"Lowest Price";
                PurchasesPayablesSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPriceCalcMethodInSetupTag());
    end;
}
#endif
