---
title: Physical triggers
layout: default
nav_order: 4
parent: Using VIAI
---
# Using the solution

## Launching physical actions based on inference results

Finally, now that you have a [local MQTT stream]({% link using-viai/usingmqtt.md %}) of real-time ML inference results, you can integrate a local system to that data stream.

This way you can for example alert human operators if a faulty product was inspected, or control a robotic arm that discards the inspected product which has a high faulty score.

To help build such a local integration, refer to the [VIAI Edge Inspection Results Action Kit document](https://docs.google.com/document/d/1ghLtMAlwMs9tah9zrBAzlDZAe9gZIcgWyQ2duIG817Q/edit?usp=sharing&resourcekey=0-zbcOEo1zY5x_9h0yBTjc4A), which shows how to build and code an inexpensive local actions prototype.
