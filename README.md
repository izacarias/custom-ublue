# My Customized Version of the Universal Blue image

This repository is a fork of the [Universal Blue Template](https://github.com/ublue-os/image-template) repository. 
The main idea is to create my own version of a [bootc](https://github.com/bootc-dev/bootc) image, packing the software the I use on a daily basis.
Many scripts, recipes, ideas and fixes are taken from the Universal Blue images, especially from the [Bluefin Project](https://projectbluefin.io/). 
I am not trying to fork or to improve Bluefin, I acually enjoy the project and the setup. This is more a learn project where I can do something nice
and also lear about [bootc](https://github.com/bootc-dev/bootc) images, which I belive are a game changer in linux world, especially on enterprise 
market. 
(I also did not like the dinossaurs that much and my daughter is afraid of them. Sorry Bluefin Team :)

In the future I plan to migrate this setup to use Hummingbird images from [Hummingbird Project](https://hummingbird-project.io/), since they also provide bootc images.

# How to use it

From a bootc system, run the following command:
```bash
sudo bootc switch ghcr.io/izacarias/custom-ublue:latest
```

# References

If you have questions about this template after following the instructions, try the following spaces:
- [Universal Blue images](https://github.com/orgs/ublue-os/packages).
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions) - This is not an Universal Blue managed space, but is an excellent resource if you run into issues with building bootc images.
