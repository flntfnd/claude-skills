# Project Architecture

Baseline: Windows App SDK 2.4 (stable, 08/13/2026), Visual Studio 2026, .NET 10 SDK. The Windows App SDK moved from the 1.x line to a semantically-versioned 2.x line during 2026 (2.0 shipped April 2026, 2.4.0 shipped August 2026) -- if you're working from older notes or a project pinned to `1.8.*`, that's not wrong for an existing app, but new projects should target the 2.x line.

## Contents

- [Terminology: WinUI vs WinUI 3](#terminology-winui-vs-winui-3)
- [Scaffolding a New Project](#scaffolding-a-new-project)
- [Package References](#package-references)
- [App.xaml Bootstrap](#appxaml-bootstrap)
- [Data Binding](#data-binding)
- [INotifyPropertyChanged / MVVM Toolkit](#inotifypropertychanged--mvvm-toolkit)

## Terminology: WinUI vs WinUI 3

Microsoft's developer documentation dropped the "3" from "WinUI 3" in 2026 -- the official current name is just **WinUI**, signaling it's the permanent framework rather than one waypoint in a series. Docs were also updated so "WinUI 2" (the UWP-era control library) is now called "WinUI for UWP." "WinUI 3" remains extremely common in the wild (blog posts, package names, Stack Overflow, most existing codebases) and is not wrong to say or search for -- treat "WinUI" and "WinUI 3" as the same thing.

<details>
<summary>Legacy / deprecated</summary>

Project Reunion was the original (2020-2021) name for what became the Windows App SDK. If you see "Project Reunion" in old code comments or docs, it's the same platform.

</details>

## Scaffolding a New Project

**Visual Studio 2026** (recommended for the visual designer): install the **WinUI application development** workload, then create a new project from the **WinUI Blank App (Packaged)** C# template.

**Command line** (any editor, or agentic workflows that need to build/run without the IDE):

```powershell
dotnet new install Microsoft.WindowsAppSDK.WinUI.CSharp.Templates
dotnet new winui -n MyWinUIApp
cd MyWinUIApp
dotnet build
dotnet run
```

`dotnet run` registers a debug identity and launches the app with MSIX package identity automatically -- no manual deployment step, no `dotnet run` limitations that used to require Visual Studio for packaged apps.

There is also a `winapp` CLI (`winget install Microsoft.WinAppCLI`) with `winapp new` (scaffold from templates: blank, NavigationView, TabView, MVVM, class library, unit-test starter), `winapp run`, and `winapp find-ui` (search WinUI Gallery / Windows Community Toolkit samples from the terminal). Useful for agent-driven development where an agent needs to scaffold, build, and inspect a running app without a human at Visual Studio.

## Package References

```xml
<!-- .csproj -->
<ItemGroup>
    <PackageReference Include="Microsoft.WindowsAppSDK" Version="2.4.*" />
    <PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.26100.*" />
</ItemGroup>

<PropertyGroup>
    <TargetFramework>net10.0-windows10.0.26100.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>
    <RuntimeIdentifiers>win-x86;win-x64;win-arm64</RuntimeIdentifiers>
</PropertyGroup>
```

`net10.0-windows10.0.26100.0` is the current template TFM (.NET 10 is the current LTS; .NET 11 is in preview as of August 2026). If a project still targets `net8.0-windows...`, that continues to build against the Windows App SDK 2.x line -- the .NET version and the Windows App SDK version are independent axes, upgrade either without the other. `TargetPlatformMinVersion` of `10.0.17763.0` (1809) is the long-standing floor for Mica/Acrylic fallback support down to Windows 10.

## App.xaml Bootstrap

```xml
<!-- App.xaml -->
<Application
    x:Class="YourApp.App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <XamlControlsResources xmlns="using:Microsoft.UI.Xaml.Controls" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

`XamlControlsResources` is required. Without it, WinUI controls won't render correctly.

## Data Binding

Use compiled bindings (`x:Bind`) over classic bindings (`Binding`) for all new code. They're type-safe, faster, and caught at compile time.

```xml
<!-- x:Bind (preferred) -->
<TextBlock Text="{x:Bind ViewModel.Title}" />
<TextBlock Text="{x:Bind ViewModel.Title, Mode=OneWay}" />
<Button Command="{x:Bind ViewModel.SaveCommand}" />

<!-- Binding (legacy, avoid for new code) -->
<TextBlock Text="{Binding Title}" />
```

## INotifyPropertyChanged / MVVM Toolkit

```csharp
// Use CommunityToolkit.Mvvm for clean MVVM
using CommunityToolkit.Mvvm.ComponentModel;

public partial class MainViewModel : ObservableObject
{
    [ObservableProperty]
    private string title = string.Empty;

    [ObservableProperty]
    private bool isLoading;

    [RelayCommand]
    private async Task LoadDataAsync()
    {
        IsLoading = true;
        try
        {
            Title = await _service.GetTitleAsync();
        }
        finally
        {
            IsLoading = false;
        }
    }
}
```
