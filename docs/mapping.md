# Details of the METS + EAD &rarr; JSON mapping

## METS

Our objects in ExploreUK, regardless of whether they have finding aids or
not, are required to have a [METS](https://www.loc.gov/standards/mets/) file.

For our purposes, the following sections are relevant:

### `dmdSec` - descriptive metadata section

Our METS files usually have a single `dmdSec` for object-level metadata, which
we record in [Dublin Core](https://www.dublincore.org/). Example:

```xml
<mets:dmdSec ID="DMD1">
    <mets:mdWrap MDTYPE="OAI_DC" MIMETYPE="text/xml">
      <mets:xmlData>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:title xml:lang="en">James Edwin Weddle Photographic Collection</dc:title>
          <dc:source>James Edwin Weddle Photographic Collection</dc:source>
          <dc:creator>Weddle, James Edwin, 1911-1989</dc:creator>
          <dc:identifier>1997av027</dc:identifier>
          <dc:subject>Horse sports.</dc:subject>
          <dc:subject>Horse racing -- Kentucky -- Lexington -- Pictorial works</dc:subject>
          <dc:subject>Thoroughbred horse.</dc:subject>
          <dc:subject>Lexington (Race horse)</dc:subject>
          <dc:publisher>University of Kentucky</dc:publisher>
          <dc:date>1948-1981</dc:date>
          <dc:format>collections</dc:format>
          <dc:type>text</dc:type>
          <dc:language>English</dc:language>
          <dc:rights>Copyright to the collection is not held by University of Kentucky. Reproduction and usage permissions can be obtained from University of Kentucky for images not identified as material published by the  Associated Press, or United Press International. Permission to reproduce those images must be secured from the individual organizations. (Identifications or publication notices are noted in the individual item records.)  Contact the Special Collections Research Center for information regarding rights and use of this collection.</dc:rights>
          <dc:description>32 Cubic Feet 66 boxes (10946 items)</dc:description>
        </oai_dc:dc>
      </mets:xmlData>
    </mets:mdWrap>
  </mets:dmdSec>
```

In particular, the `dc:source` element is human-readable shared metadata for individual items within
a collection.

### `fileSec` - file section

We organize `fileSec` into a number of `fileGrp`s. Files within a `fileGrp` are different manifestations
of the same underlying object. Example:

```xml
<mets:fileGrp ID="FileGrp115">
  <mets:file ID="ThumbnailFilee32d581c82b0079697654b79be4347e9" USE="thumbnail" MIMETYPE="image/jpeg">
    <mets:FLocat xlink:href="1997av027/Box_2/Item_115/1997av027_0115_tb.jpg" LOCTYPE="OTHER"/>
  </mets:file>
  <mets:file ID="FrontThumbnailFile104dbe363f0e8f263dab0c52557b64ba" USE="front thumbnail" MIMETYPE="image/
jpeg">
    <mets:FLocat xlink:href="1997av027/Box_2/Item_115/1997av027_0115_ftb.jpg" LOCTYPE="OTHER"/>
  </mets:file>
  <mets:file ID="ReferenceImageFile991ff9a4b7d76b6f8dbee2d7746e58e2" USE="reference image" MIMETYPE="image/
jpeg">
    <mets:FLocat xlink:href="1997av027/Box_2/Item_115/1997av027_0115.jpg" LOCTYPE="OTHER"/>
  </mets:file>
  <mets:file ID="PrintImageFilef19cc4a2d47746ad4263e294ecaa80ae" USE="print image" MIMETYPE="application/pd
f">
    <mets:FLocat xlink:href="1997av027/Box_2/Item_115/1997av027_0115.pdf" LOCTYPE="OTHER"/>
  </mets:file>
</mets:fileGrp>
```

In this example, all four files represent
[digitized versions](https://exploreuk.uky.edu/catalog/xt734t6f3d29_115_1)
of the same physical artifact, with different
uses (such as "thumbnail" or "reference image").

For collections with finding aids, there is a special `fileGrp`
which references the EAD file or files associated with the collection.

```xml
<mets:fileGrp ID="FileGrpFindingAid" USE="Finding Aid">
  <mets:file ID="MasterFindingAid" MIMETYPE="application/xml" USE="master">
    <mets:FLocat LOCTYPE="OTHER" xlink:href="1997av027.xml"/>
  </mets:file>
  <mets:file ID="AccessFindingAid" MIMETYPE="application/xml" USE="access">
    <mets:FLocat LOCTYPE="OTHER" xlink:href="1997av027.dao.xml"/>
  </mets:file>
</mets:fileGrp>
```

This allows the EAD file, the encoded finding aid, to be discovered,
given access to the METS file and its containing DIP.

### `structMap` - structural link section

We use the `structMap` to document a logical reading order for digital objects. For finding aids, we use
a two-level structure. The top level divides a collection into "sections", and the lower level serves as
pagination within a section. Depending on how the collection is organized, sections may have a single "leaf"
or many. Example:

```xml
<mets:div TYPE="section" LABEL="115" ORDER="115">
  <mets:div TYPE="photograph" LABEL="Animals; Cats; Close-up of kitten" ORDER="1">
    <mets:fptr FILEID="ThumbnailFilee32d581c82b0079697654b79be4347e9"/>
    <mets:fptr FILEID="FrontThumbnailFile104dbe363f0e8f263dab0c52557b64ba"/>
    <mets:fptr FILEID="ReferenceImageFile991ff9a4b7d76b6f8dbee2d7746e58e2"/>
    <mets:fptr FILEID="PrintImageFilef19cc4a2d47746ad4263e294ecaa80ae"/>
  </mets:div>
</mets:div>
```

The `FILEID` attribute in the `fptr` element matches the `ID` attribute of the corresponding `file`
in the `fileSec`.

## EAD

Our finding aid collections in ExploreUK generally have an [EAD](https://loc.gov/ead/) file.
Content managers decide whether to process specific collections with or without EADs.
The finding aid viewer and the METS + EAD &rarr; JSON converter only handle
collections which have both METS and EAD.

As of April 2024, we continue to use the EAD 2002 standard.

## JSON

This software reads a METS file, uses that to find the access copy of the EAD,
then extracts metadata from both files, organizing them into a JSON object.

### A skeletal JSON object

```json
{
  "header": {
    "abstract": "...",
    "descriptive_summary": {
      "title": "...",
      "date": "...",
      "creator": "...",
      "extent": "...",
      "subjects": ["...", "..."],
      "arrangement": "...",
      "finding_aid_author": "...",
      "preferred_citation": "..."
    },
    "collection_overview": {
      "biography_history": "...",
      "scope_and_content": "...",
      "processing_info": "..."
    },
    "restrictions_on_access_and_use": {
      "conditions_governing_access": "...",
      "use_restrictions": "..."
    },
    "special_links": {
      "ead": "https://...",
      "more_from_this_collection": "https://..."
    }
  },
  "contents_of_the_collection": [
    /* described below */
  ]
}
```

### `contents_of_the_collection`

The `contents_of_the_collection` field is an array of entries. Each entry
corresponds to a **[component](https://loc.gov/ead/tglib/elements/c.html)**
of the collection. Every entry should have at least the following fields:

* `id`
* `level`
* `title`

In uncommon cases, an entry will also have the following fields:

* `biography_history`
* `scope_and_content`
* `title`

A component in a collection can have subcomponents, and the value of
the `subcomponents` field is an array of entries corresponding to those
subcomponents, recursively.

A component can have one or more container lists. These are listed in the
`container_lists` field. A container list should have the following fields:

* `id`
* `summary`
* `volume`
* `container`
* `container_list`

If there is digitized content corresponding to a component, links to that
content should be stored in the `links` field. Each entry in the links field
can have one or more subentries, one for each manifestation of a file in the
digitized object. Example:

```json
"links": [
  [
    [
      {
        "id": "xt734t6f3d29_1_1_thumbnail",
        "use": "thumbnail",
        "mimetype": "image/jpeg",
        "href": "1997av027/Box_1/Item_1/1997av027_0001_tb.jpg"
      },
      {
        "id": "xt734t6f3d29_1_1_reference_image",
        "use": "reference image",
        "mimetype": "image/jpeg",
        "href": "1997av027/Box_1/Item_1/1997av027_0001.jpg"
      }
    ]
  ]
],
```
