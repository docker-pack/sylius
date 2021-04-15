<p align="center">
    <a href="https://sylius.com" target="_blank">
        <img src="https://demo.sylius.com/assets/shop/img/logo.png" />
    </a>
</p>

<h1 align="center">Easy install Sylius using docker</h1>

<p align="center">This is an easy way to install Sylius Standard Edition repository using docker & docker-compose.</p>

About
-----
This project is an easy way to simplify the install [**Sylius Standard Edition**](https://github.com/Sylius/Sylius-Standard) using docker & docker-comppose & make filemake.
Sylius is the first decoupled eCommerce platform based on [**Symfony**](http://symfony.com) and [**Doctrine**](http://doctrine-project.org).
The highest quality of code, strong testing culture, built-in Agile (BDD) workflow and exceptional flexibility make it the best solution for application tailored to your business requirements.
Enjoy being an eCommerce Developer again!


Documentation
-------------

TODO

Installation
------------
First run 
```bash
$ make install
```
It will generate a .env file check this file and configure the apache outside docker port or if want to use mysql docker or external mysql database
and then re-execute 
```bash
$ make install
```
It will create, download and install sylius