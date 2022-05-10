## Introduction

This repository introduces a tool and a workflow for reporting on urban heat and urban heat inequity. The tool visualizes temperatures sourced from satellite imagery. It juxtaposes the temperatures with infrastructural, environmental, and demographic variables that are relevant to reporting on and understanding urban heat.

<img width="100%" alt="image" src="https://user-images.githubusercontent.com/15334952/167740143-43b4a4ec-ea3e-47ee-b158-1a015620cef5.png">
_A screenshot of the interactive tool._

## Use case: Port Morris

An example use case of this workflow might be as follows. 

<img width="100%" alt="image" src="https://user-images.githubusercontent.com/15334952/167740266-e03ffbea-d3c1-45c7-90b2-650a121e52dd.png">

On the tool, you can just view temperature in a certain year. (Yellow signifies hotter, and blue signifies colder.) In the view above, near the "PORT MORRIS" label, you can see an area of dark yellow stretching upwards. If you toggle on the impervious surfacing layer...

<img width="100%" alt="image" src="https://user-images.githubusercontent.com/15334952/167740852-f7fc90d7-2fa6-41dc-a1ab-90f241a4d208.png">

... you see that the entire stretch has a high amount of impervious surfacing. This serves as a jumping off point for further research. Indeed, in this example, the stretch by Port Morris has received heavily criticism in the local community for its power plants, trucking operations, and other industrial facilities contributing to heat and pollution.

## Reproduction and development

The `visuals/` directory contains the website/interactive tool. After running `npm installl`, Run `npm run dev -- --open` to open the website at `localhost:3000`.
