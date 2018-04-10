# GiD Smart Wizards

## The idea
The main idea of this package is to allow GiD problemtype developers to create a wizard interface easy, just configuring an xml file an defining a few tcl procs. Check the example here -> [CMas2D CustomLib Wizard](https://github.com/GiDHome/cmas2d_customlib_wizard).

## About this package
This tcl package is included in the 14th version of the [GiD pre and post processor](http://www.gidhome.com). 
It uses the following packages:
* gid_wizard: Available in the scripts folder of GiD
* wcb: The Widget CallBack. A package that checks the input of an entry field, by Csaba Nemethi, available [here](http://www.nemethi.de/wcb/wcbRef.html)
* tdom: A package to handle xml documents. Available [here](http://tdom.github.io)

All the packages defined here are distributed inside GiD, and the library import them. The developers do not need to require them.

## Usage:
First thing to do is to define your steps. You can create all your steps using this easy way, but you can also code a step manually. There are no restrictions if you code the step manuelly, you are allowed to use all the elements in TK, but this package helps you only if you try to do something "standard" like asking the user to insert:
    * input
        * integers
        * doubles
        * strings
    * combobox - selector
    * button
    * text label
    * image
    
### XML configuration:
A wizard layout is defined in a xml file. This is the basic structure:

#### XML Tags
* **Wizard**: Is the root node, it must contain:
  * version: For version controlling.
  * wizardid: Identifier of the wizard. will be used in the internal data structures and in the window naming.
  * title: Will be placed in the top of the wizard window.
* **Steps**: Just a container of steps. It has no attributes.
* **Step**: They belong to the Steps container. The system will create a 'window' for each of this steps. They must be placed here in order and must contain:
  * id: Will be used in the internal data structures.
  * title: Public name shown in the top of the window.
  * subtitle: Will be shown below the title.
* **Data**: Just a container inside a step. It has no attributes.
* **Frame**: We split the window layout in 2 sections, left and right. We can define as many frames as we want and place them in one of these sections. Mapping to a html component, a frame is like a div. Must contain:
  * n: Internal name, will be used in the internal data structures. Must be unique in a step.
  * postion: left or right.
  * title: (optional) If title exists, a ttk:labelframe will be placed, else, a normal bordered ttk::frame.
* **Item**: They belong to a frame. Mapping to a html component, a item is like a input. It must contain:
  * n: Internal name, will be used in the internal data structures. Must be unique in a step.
  * pn: Public name. Will be converted into a ttk::label and placed in the first position (left align).
  * v: Value of the item. It's the default value.
  * type: As a html input, we can define item types:
    * integer: v must be an integer, and the wcb package will prevent user to insert any strange character. It will be displayed as a ttk::entry.
    * double: v must be an double, and the wcb package will prevent user to insert any strange character. It will be displayed as a ttk::entry.
    * string: v can be anything. It will be displayed as a ttk::entry.
    * label: v can be anything. It will be displayed as a ttk::label.
    * combo: v can be one of the options defined in values. Mapping to a html component, a combo is like a select. It will be displayed as ttk::combobox. It must contain:
      * values: Defines the available values in the dropdown. Values can be defined as a static list, separated by commas, or as a dynamic list, using a tcl function that must return a commas separated string (see example NumberOfLoads).
      * onchange: (optional) TCL function called when the combo value is changed by the user. Usefull to create dependencies manually.
    * image: v must the the imagename (picture.png) NOT THE PATH

#### XML conventions

* Steps will be shown in the same order they appear in the XML.
* Frames will be shoen in the same order they appear in the step.
* I recommend to use titleless frames to place images.
* Use \n in labels to create line breaks.
* Use png or jpg images. Animated gifs will not move, don't try it... :cry:

### TCL implementation

:bulb: Disclaimer: If you are here, I assume that you know how to create a problemtype in GiD, and know the basics of TCL.

