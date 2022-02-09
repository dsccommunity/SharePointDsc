In some circumstances you may find yourself needing to use a [Script resource](https://msdn.microsoft.com/en-us/powershell/dsc/scriptresource) to be able to perform a function that is not included in SharePointDsc. If your script resource needs to add the SharePoint snap-in you may find that this will cause issues with other resources provided by SharePointDsc (as discussed in in [this issue](https://github.com/PowerShell/SharePointDsc/issues/566)). To work around this, it is recommended that instead of loading the snap-in yourself you use the Invoke-SPDscCommand helper to achieve this. This helper method will load the snap-in for you in the same way that the native resources of SharePointDsc do, and will avoid conflicts with it being loaded multiple times.

An example of this in a script resources is shown below:

```PowerShell
Script SPDscExample
{
  GetScript = {
    Invoke-SPDscCommand -ScriptBlock {
      # your code goes here
      $params = $args[0]
      Write-Verbose $params.Foo
    } -Arguments @{ Foo = "Bar" } -Credentials (Get-Credentials)
  }
  ...
}
```

If you need to pass a credential or additional arguments, you can use the -Credential and -Arguments parameters for these purposes also.