# Blob-timelapse
Create a timelapse using a Raspberry Pi and a Pi Camera

# Projet : [Élève ton Blob](https://disciplines.ac-toulouse.fr/stc3/eleve-ton-blob-lexperience-educative-du-cnes-pour-la-mission-alpha)
Le [CNES](https://enseignants-mediateurs.cnes.fr/fr/elevetonblob-lexperience-educative-du-cnes-pour-la-mission-alpha) propose de participer à des expériences basées sur l'étude du comportement du *Physarum Polycephalum* (alias le Blob) en collaboration avec la mission Alpha de Thomas Pesquet.
Il s'agit de comparer le comportement du Blob sur Terre dans les conditions de pesanteur terrestre avec son comportement en microgravité dans l'ISS.
Pour mesurer le comportement, des photos de son évolution doivent être prises suivant les différents protocoles proposés.
Le Blob ne supportant pas la lumière, il doit être placé dans un endroit sombre. Il faut donc éclairer la scène aux moments idoines lors des prises de photos.

Pour prendre les photos, la solution suivante a été utilisée :
* utilisation d’un Raspberry Pi et d’une Pi Camera, d’une LED et d’un script Bash pour la prise de photos à intervalles régulier.
* mise en place d’un serveur web (Apache) pour la consultation des photos prises et vérifier l’état du Blob sans ouvrir la boite pendant la durée de l’expérience.
* utilisation de ffmpeg pour la réalisation d’un timelapse à partir des photos.

## Pré-requis : 
* 1 Raspberry Pi 3 ou 4 : [lien](https://www.kubii.fr/kits-raspberry-pi-3-et-3/1637-starter-kit-officiel-pi3-kubii-3272496004207.html?search_query=kit+raspberry+pi&results=172) 
* 1 Raspberry Pi Camera v2 (ou v1) : [lien](https://www.kubii.fr/cameras-accessoires/1653-module-camera-v2-8mp-kubii-5060214370240.html?search_query=pi+camera&results=120)
* 1 Relais type Mosfet : [lien](https://www.seeedstudio.com/Grove-MOSFET.html) ou [lien](https://fr.aliexpress.com/item/32816461739.html?spm=a2g0o.productlist.0.0.447a79a25BkAiL&algo_pvid=d10ba7bc-eb65-4796-a440-b98fa44be92e&algo_exp_id=d10ba7bc-eb65-4796-a440-b98fa44be92e-0)
* 1 LED (1W) : [lien](https://fr.aliexpress.com/item/4001197438816.html?spm=a2g0s.9042311.0.0.27426c37cA3bvZ)
* Jumper cables (femelle-femelle, male-femelle, male-male) : [lien](https://www.kubii.fr/rechercher?controller=search&orderby=position&orderway=desc&search_query=jumper+cable&submit_search=)

## Montage : 
La complexité du montage réside dans le fait qu’il n’est pas possible d'alimenter directement la LED à partir d'une broche GPIO. Le courant de sortie est trop faible : 20-30mA.
Il faut donc utiliser un relais (un transistor Mosfet), piloté depuis une broche GPIO, pour jouer le rôle d'interrupteur. On pourra alors utiliser la broche +5V ou +3.3V, qui elles, permettent un courant bien supérieur.
Le choix de la LED s’est porté sur une LED de 1W avec une tension VF comprise entre 3.2-3.6V. En utilisant la broche power 3.3V du Raspberry Pi, il n’y pas besoin de résistance pour limiter le courant. 

>Apparté électronique :
>Par sécurité, il serait conseillé de mettre une résistance devant la LED (15ohm suffisent). Mais sans résistance, le montage réalisé avec les composants présentés en prérequis fonctionne sans accroc sur de longues périodes.

Avec l'alimentation 3.3V on obtient un courant de 240mA environ, soit un flux lumineux idéal pour éclairer le Blob.

Pour le montage, il faut connecter la broche +3.3V du Raspberry Pi sur l'entrée + du Mosfet, ainsi que le GND sur le GND du Raspberry Pi. Puis enfin, connecter l’Out sur l'anode de la LED.

![alt text](https://github.com/H0henheim/Blob-timelapse/blob/42f21e59c9c31b467f02b34a1615ffa22855a4ea/ressources/schema_montage_blob_white.png)

## Installation :
Nous partons du principe que Raspbian est installé sur le Raspberry Pi (voir ce [tutoriel](https://www.raspberrypi-france.fr/guide/installer-raspbian-raspberry-pi/))

```bash
# création d’un nouveau user blob
sudo adduser blob
# ajout des droits superuser au user blob
sudo visudo → blob    ALL=(ALL:ALL) ALL
su blob
# suppression du user pi
sudo deluser -remove-home pi
# ajout du user blob au groupe gpio et video pour le contrôle des pins GPIO et de la caméra
sudo usermod -aG gpio blob
sudo usermod -aG video blob
# MaJ du système
sudo apt update
sudo apt upgrade
# installation du serveur web
sudo apt install apache2
sudo apt install php php-mbstring
# attribution des droits sur le répertoire web
sudo chown -R blob:www-data /var/www/html
sudo chmod 770 /var/www/html/
# activation des pins GPIO et de la caméra
sudo raspi-config → enable GPIO and camera
```

## Test :
```bash
raspistill -o testshot.jpg
```
→ Il faut régler la focale de la caméra pour avoir une bonne netteté à faible distance ([lien](https://www.jeffgeerling.com/blog/2017/fixing-blurry-focus-on-some-raspberry-pi-camera-v2-models)).

```bash
sudo ./ledcontrol.sh
```
→ Pour vérifier que l’allumage et l’extinction de la LED fonctionne.

## Usage

Start timelapse :
```bash
sudo ./timelapse.sh &
```

## Explication :

La fonction *timelapse()* permet de prendre les photos à intervalle régulier sur une période de temps.

La variable *sample_period* permet de définir l’intervalle de temps entre 2 photos. Il est exprimé en seconde.

La variable *nb_picture* permet de définir le nombre de photos qui seront prises.

> Durée de l’expérience = *sample_period* x *nb_pictures*

Si l’on souhaite que l’expérience dure 24h (soit 86400 secondes) avec un intervalle de 10 minutes entre chaque prise (600 secondes) alors *nb_pictures* = 86400 / 600 = 144 photos

La fonction *take_picture()* prend les photos en utilisant l’utilitaire *raspistill* présent de base sur la distribution.
Chaque photo est nommée suivant le pattern suivant : timelapse_YY-mm-dd_HH:MM:SS.jpg.
Cela permet de faire apparaître l’horodatage directement dans le nom de photo, ce qui plus commode à utiliser et à visualiser que de rechercher ces informations dans les propriétés du fichier.

Il y a deux fonctions d’encodage pour créer la vidéo de timelapse à partir des photos prises :
* *encoding_1()* utilise mencoder (basé sur ffmpeg) et produit un timelapse de moyenne résolution avec poids faible et un traitement rapide pour le processeur du Pi.
* *encoding_2()* utilise directement ffmpeg et produit un timelapse avec une résolution HD (1080p). Le traitement de l’encodage est plus long (compter 5 minutes pour 144 photos à 15fps) pour poids d’environ 150Mo.

*encoding_2()* se veut lossless, là où *encoding_1()* se veut rapide et léger.

Les 2 fonctions peuvent s’utiliser en fonction des besoins, il suffit de changer le code en décommentant la ligne avec la fonction voulue et en commentant l’autre.

```bash
echo -e "Starting timelapse"
create_dir
timelapse
echo -e "Creating video..."
#encoding_1
encoding_2
echo -e "Done"
```

Les vidéos produites sont à 15fps mais ce paramètre peut être modifié au niveau des fonctions *encoding_1()* et *encoding_2()*.

A 15fps, 6 jours de capture produisent une vidéo d’une durée d’environ 1 minute.

Les autres fonctions sont des fonctions utilitaires. L’intérêt de les décrire ici n’est pas pertinent.

>A noter que le script se lance avec les droits superuser (sudo). Ceci est lié aux fonctions manipulant les pins GPIO.
>Il semble exister des possibilités pour manipuler les pins GPIO en tant que user normal mais la mise en œuvre est loin d’être simple et ne semble pas parfaitement fonctionnelle. ([lien](https://www.udoo.org/forum/threads/accessing-gpio-without-root.7949/))

Comme *timelapse.sh* est lancé sur une période assez longue (24h à une semaine suivant les protocoles expérimentaux), il est important de ne pas lier le processus au terminal qui le lance.

Pour cela il faut utiliser l’exécutable *nohup*.
```bash
sudo nohup ./timelapse.sh & --> le & est important pour ne pas bloquer le terminal).
```

Cette commande a le défaut de ne pas faire apparaître le prompt de sudo demandant le mot de passe de l’utilisateur.
Afin de palier à cela, la mécanique suivante est employée :

```bash
sudo su
exit
sudo nohup ./timelapse.sh &
```

Le mot de passe de l’utilisateur ayant été demandé pour la commande *sudo su*, il ne le sera normalement pas pour la commande *sudo nohup ./timelapse.sh* (comportement que l’on retrouve sur les distro type Debian/Ubuntu notamment).

Dernier point : un fichier de log *timelapse.log* s’alimente dans le répertoire où sont stockées les photos. Il permet de suivre l’évolution des prises de vue et détecter si un souci est survenu (notamment l’arrêt du script pour une raison X).

## Aperçu :

<img src="https://github.com/H0henheim/Blob-timelapse/blob/42f21e59c9c31b467f02b34a1615ffa22855a4ea/ressources/20211021_140225.jpg" height="500" width="300"> <img src="https://github.com/H0henheim/Blob-timelapse/blob/42f21e59c9c31b467f02b34a1615ffa22855a4ea/ressources/apache_screen_1.png" height="230" width="300"> <img src="https://github.com/H0henheim/Blob-timelapse/blob/42f21e59c9c31b467f02b34a1615ffa22855a4ea/ressources/apache_screen_2.png" height="230" width="300">

## Vidéo produite :

[![Blob Timelapse](https://img.youtube.com/vi/KnkiHxeuSHA/hqdefault.jpg)](https://youtu.be/KnkiHxeuSHA)











