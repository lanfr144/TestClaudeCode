The current version is #ident "@(#)$Format:LocalFoodAI_lanfr144:Header_Footer_Gemini.md:Francois Lange:lanfr144@school.lu:2026/06/17 12:00:57:Francois Lange:lanfr144@school.lu:2026/06/17 12:00:57:Not Committed Yet:local:none$"

# PDF Header and Footer Generation Guidelines (Gemini Standard)

This document describes how to implement standard headers and footers using the Gemini declarative styling approach. This model uses CSS Paged Media specifications to design page layouts directly during HTML-to-PDF compilation.

## 1. Concept

Unlike programmatic post-processing, the Gemini approach relies on standard CSS Page Margin Boxes defined within the `@page` context. The layout engine allocates page margin spaces and positions the logos, titles, and page numbers based on CSS property rules.

## 2. Page Margin Box Layout Model

The CSS Paged Media margin boxes are structured as follows around the main page area:

```mermaid
graph TD
    subgraph Page Box [W3C Page Margin Box Grid]
        subgraph Top Margin Boxes
            TopLeft["@top-left Box<br/>(am.png Logo<br/>max-height: 24.5pt)"]
            TopCenter["@top-center Box<br/>(Centered Document Title)"]
            TopRight["@top-right Box<br/>(Bts.png Logo<br/>max-height: 36.8pt)"]
        end
        
        subgraph Middle Box
            MainPage["Page Content Area<br/>(Markdown Flowables)"]
        end
        
        subgraph Bottom Margin Boxes
            BottomLeft["@bottom-left Box<br/>(User ID: lanfr144)"]
            BottomCenter["@bottom-center Box<br/>(Page X of Y)"]
            BottomRight["@bottom-right Box<br/>(Project: DOPRO1)"]
        end
    end
    
    TopLeft -.-> MainPage
    TopCenter -.-> MainPage
    TopRight -.-> MainPage
    MainPage -.-> BottomLeft
    MainPage -.-> BottomCenter
    MainPage -.-> BottomRight
```

## 3. CSS Declaration Example

To implement the Gemini standard paged layout, include the following CSS rules inside the stylesheet used by the PDF engine:

```css
@page {
    size: A4;
    margin: 60pt 48pt 54pt 48pt; /* Set top margin to 60pt to prevent collisions */
    
    @top-left {
        content: url("am.png");
        image-resolution: 300dpi;
        vertical-align: middle;
        z-index: -1; /* Place in background */
    }
    
    @top-center {
        content: "Document Title";
        font-family: 'Helvetica', sans-serif;
        font-size: 8pt;
        color: #808080;
        vertical-align: middle;
        text-align: center; /* Center between left/right margin boxes */
    }
    
    @top-right {
        content: url("Bts.png");
        image-resolution: 300dpi;
        vertical-align: middle;
    }
    
    @bottom-left {
        content: "lanfr144";
        font-family: 'Helvetica', sans-serif;
        font-size: 8pt;
        color: #808080;
    }
    
    @bottom-center {
        content: "Page " counter(page) " of " counter(pages);
        font-family: 'Helvetica', sans-serif;
        font-size: 8pt;
        color: #808080;
    }
    
    @bottom-right {
        content: "DOPRO1";
        font-family: 'Helvetica', sans-serif;
        font-size: 8pt;
        color: #808080;
    }
}
```
