#!/bin/bash

##### Script de préparation des clients/serveurs et de rollback des clients.


### Pour lancez le script à partir du serveur DHCP fraichement installé, executez ./initiate.sh avec un des arguments suivants :

## "server-first" A lancer en premier sur un serveur fraichement installé.
## "server-key" Pour créer et diffuser la clé publique du serveur afin d'administrer les postes clients en ssh.
## "server-copy-script" Pour copier le script sur les postes clients.
## "server-deploy-script" Pour déployer le script de configuration sur les postes clients.
## "server-deploy-rollback' Pour effectuer le rollback des postes clients.
## "server-test-network" Pour lancer les vérifications réseau.

### Vous pouvez lancer le script ./initiate.sh individuellement sur les postes clients avec les arguments suivants :

## "client-first" A lancer en premier sur un poste client fraichement installé (redémarrage automatique à la fin).
## "client-rollback" Pour lancer la procédure de retour en arrière des postes clients (execution de "client-first" au préalable nécessaire ! ).
## 'test-network' Pour lancer les tests de réseau.


### Lorsque vous y êtes invité - [O/n], veuillez répondre par o (oui) ou n (non).


##### Pour de plus amples explications, veuillez vous référer au fichier : "AFL - Procédure d'installation du réseau et des postes de formation"



message='Bienvenue chez à fond linux ! '
echo "$message"

## A LANCER EN PREMIER APRES UNE INSTALLATION FRAICHE DU CLIENT !
# Sauvegarde des fichiers et changement de hostname.

if [ $# -ge 1 ] && [ $1 = 'client-first' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"
	echo 'ATTENTION ! Le système va redémarrer automatiquement à la fin du script ! '
	
	echo 'Mise à jour du système '
	echo SprVsr | sudo -S apt-get update
	echo SprVsr | sudo -S apt-get -y upgrade
	echo 'Système mis à jour. '
	echo 'All is done ! '	

	echo 'Sauvegarde des fichiers hosts et hostname'
	echo SprVsr | sudo -S cp /etc/hosts /etc/hosts-old
	echo 'Fichier hosts sauvegardé'
	echo SprVsr | sudo -S cp /etc/hostname /etc/hostname-old
	echo 'Fichier hostname sauvegardé'
	echo 'All is done ! '

	echo 'Installation de vim'
	echo SprVsr | sudo -S apt-get -y install vim
	echo 'All is done ! '

	echo 'Création des utilisateurs prédéfinis pour les formations.'
	echo "Création de l'utilisateur 'admininfra'. "
	echo SprVsr | sudo -S useradd -m -p $(openssl passwd -1 sprvsr) admininfra
	echo "Utilisateur 'admininfra' créé. "
	echo SprVsr | sudo -S usermod -a -G sudo admininfra
	echo "Utilisateur 'admininfra' ajouté au groupe 'sudo'. "
	echo 'Vérification : '
	id admininfra
	echo 'All is done ! '

	echo "Création de l'uilisateur 'student'. "
	echo SprVsr | sudo -S useradd -m -p $(openssl passwd -1 aflstud) student
	echo "Utilisateur 'student' créé. "
	echo 'Vérifcation : '
	id student
	echo 'All is done ! '

	echo 'Changement de hostname'
	echo 'Création du suffixe numérique du hostname'
	val=$(( RANDOM % 100 + 1 ))
	hostn=$(cat /etc/hostname)
	echo "Ancien hostname : $hostn "
	echo 'Définition du hostname'
	echo SprVsr | sudo -S sed -i "s/$hostn/AFL1DSK$val/g" /etc/hosts
	echo SprVsr | sudo -S sed -i "s/$hostn/AFL1DSK$val/g" /etc/hostname
	echo 'Vérifications : '
	hostnamectl
	echo 'All is done ! '

	echo 'Le système va maintenant redémarrer pour appliquer les changements. '
	echo SprVsr | sudo -S reboot
	exit


## A LANCER APRES UNE INSTALLATION FRAICHE DU SERVEUR !
# Installation de PIP et pssh, listing des IP et création du fichier ip_arp et des dossiers /etc/ARP et /etc/psssh.

elif [ $# -ge 1 ] && [ $1 = 'server-first' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Mise à jour du système'
	sudo apt-get update
	sudo apt-get -y upgrade
	echo 'Système mis à jour. '
	echo 'All is done !'

	echo 'Installation des packages nécessaires'
	echo 'Installation de nmap'
	sudo apt-get -y install nmap
	echo 'nmap installé'
	echo 'Installation de isc-dhcp-server'
	sudo apt-get install -y isc-dhcp-server
	echo 'isc-dhcp-server installé'
	echo 'Installation de iptables-persistent'
	sudo apt-get install -y iptables-persistent
	echo 'iptables-persistent installé'
	echo 'Installation de PIP'
	sudo apt-get install -y python-pip
	echo 'PIP installé'
	echo 'Installation de pssh'
	yes | sudo pip install pssh
	echo 'pssh installé. '
	echo 'All is done ! '

	echo 'Création et sauvegarde des règles iptables'
	echo 'Création de la règle iptables'
	sudo iptables -t nat -A enp0s3 -j MASQUERADE
	echo 'Règle créé'
	echo 'Sauvegarde de la règle'
	sudo netfilter-persistent save
	echo 'Règle sauvegardé'
	echo 'Application des changements'
	sudo netfilter-persistent reload
	echo 'Changements appliqués'
	echo 'All is done ! '

	echo 'Changement du hostname'
	hostn=$(cat /etc/hostname)
	sudo sed -i "s/$hostn/AFL1ROU0001/g" /etc/hosts
	sudo sed -i "s/$hostn/AFL1ROU0001/g" /etc/hostname
	echo 'Vérifications : '
	hostnamectl
	echo 'All is done ! '

	echo 'Le système doit redémarrer pour appliquer les changements'
	while true; do
		read -p 'Voulez-vous redémarrer maintenant ? [O/n] ' on
		case $on in
			[Oo]* ) /sbin/reboot; break;;
			[Nn]* ) echo 'Merci de redémarrer pour appliquer les changements'; exit;;
			* ) echo "Merci de répondre par o (oui) ou n (non)";;
		esac
	done
	echo 'All is done ! '
	echo 'Fin du script, bye ! '
	exit



## A LANCER APRES AVOIR EXECUTE "server-first" ! TOUS LES POSTES CLIENTS CIBLES DOIVENT ETRE BRANCHE AU RESEAU !
# Création et diffusion de la clé ssh RSA.

elif [ $# -ge 1 ] && [ $1 = 'server-key' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Nettoyage des fichiers existants'
	sudo rm ip_nmap
	sudo rm iplist_nmap
	sudo rm pssh_hosts
	echo 'Fichiers existant supprimés. '
	echo 'All is done ! '
	
	echo 'Création du fichier iplist_nmap'
	echo 'Scan des réseaux'
	ip=$(nmap -sP 192.168.100.0/24 192.168.101.0/24)
	echo 'Résultat : '
	echo $ip
	echo 'Génération du fichier iplist_nmap'
	echo $ip >> ip_nmap
	grep -o -P '(?<=for).*?(?=Host)' ip_nmap >> iplist_nmap	
	echo 'Vérification : '
	echo $(ls)
	echo 'All is done ! '

	echo 'Création du fichier pssh_hosts'
	echo 'Recupération des IP'
	hosts=$(awk '!/192.168.100.254|192.168.101.254/' iplist_nmap)
	echo 'Génération du fichier pssh_hosts'
	echo "$hosts" >> pssh_hosts
	echo 'Vérification : '
	echo $(ls)
	echo 'All is done ! '

	echo "Création de la clé RSA"
	echo -ne '\n' | ssh-keygen -t rsa
	echo 'Clé RSA créé. '
	echo 'All is done ! '

	echo 'Diffusion de la clé RSA vers les postes clients'
	for ip in `cat pssh_hosts`;
	do ssh-copy-id -i ~/.ssh/id_rsa.pub $ip
	done
	echo 'All is done ! '

	echo 'Fin du script, bye ! '
	exit

	
## A LANCER APRES server-first !
# Copie du script sur les postes clients.

elif [ $# -ge 1 ] && [ $1 = 'server-copy-script' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1. "

	echo 'Copie du script sur les postes clients'
	pscp -h pssh_hosts -l aic initiate.sh /home/aic
	echo 'Script copié. '
	echo 'All is done ! '
	echo 'Fin du script, bye ! '
	exit


## A LANCER APRES server-copy-script !
# Déploiement du script de configuration sur les postes clients.

elif [ $# -ge 1 ] && [ $1 = 'server-deploy-script' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Déploiement du script sur les postes clients' 
	pssh -h pssh_hosts -l aic -i "./initiate.sh client-first"
	echo 'Script de configuration des postes clients déployé. ' 
	echo 'All is done ! '
	echo 'Fin du script, bye!'
	exit


## A LANCER APRES server-deploy-script !
# Déploiement du script de rollback sur les postes clients.

elif [ $# -ge 1 ] && [ $1 = 'server-deploy-rollback' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Lancement du rollback des postes clients'
	pssh -h pssh_hosts -l aic -i "./initiate.sh client-rollback"
	echo 'Rollback effectué'
	echo 'All is done ! '

	echo 'Redémarrage de la machine'
	pssh -h pssh_hosts -l aic -i "echo SprVsr | sudo -S reboot now"
	exit


## A LANCER SI LA PARTIE "client-first" A ETE EFFECTUE AUPARAVANT !
# Rollback, restauration des paramètres d'origines.

elif [ $# -ge 1 ] && [ $1 = 'client-rollback' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Mis à jour du système'
	echo SprVsr | sudo -S apt-get update
	echo "Suppression des utilisateurs créés"	
	echo "Suppression de l'utilisateur 'admininfra'"
	sudo deluser admininfra --remove-all-files
	sudo delgroup admininfra
	echo "Utilisateur 'admininfra' supprimé. "
	echo "Suppression de l'utilisateur 'student'"
	sudo deluser student --remove-all-files
	sudo delgroup student
	echo "Utilsateur 'student' supprimé. "
	echo 'All is done ! '

	echo 'Restauration des fichiers hosts et hostname'
	echo SprVsr | sudo -S mv /etc/hosts-old /etc/hosts
	echo 'Fichier hosts restauré'
	echo SprVsr | sudo -S mv /etc/hostname-old /etc/hostname
	echo 'Fichier hostname restauré. '
	echo 'Vérification du hostname'
	hostnamectl
	echo 'All is done ! '
	echo 'Le système va redémarrer pour appliquer les changements, bye ! '
	echo SprVsr | sudo -S reboot now
	exit


## A LANCER POUR TESTER LE RESEAU EN MASSE DEPUIS LE SERVEUR DHCP !
# Test fping et écriture dans des fichiers.

elif [ $# -ge 1 ] && [ $1 = 'server-test-network' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1"

	echo 'Lancement du script'
	pssh -h pssh_hosts -l aic -i "./initiate.sh test-network"
	echo 'All is done ! '
	echo 'Fin du script, bye ! '
	exit


## A LANCER POUR VERIFIER LE RESEAU ! A LANCER INDIVIDUELLEMENT !
# Ping des différentes ip sur le réseau.

elif [ $# -ge 1 ] && [ $1 = 'test-network' ]
then
	echo "Vous avez choisis le script $0 avec l'option $1. "

	echo 'Installation de fping'
	echo SprVsr | sudo -S apt-get -y install fping
	echo 'fping installé. '
	echo 'Supression des anciens fichiers'
	echo SprVsr | sudo rm test-subnet0
	echo SprVsr | sudo rm test-subnet100
	echo SprVsr | sudo rm test-subnet101
	echo 'All is done ! '

	echo 'Lancement des vérifications'
	test1=$(fping -aq -g 192.168.0.0/24)
	echo $test1
	echo $test1 >> test-subnet0
	test2=$(fping -aq -g 192.168.100.0/24)
	echo $test2
	echo $test2 >> test-subnet100
	test3=$(fping -aq -g 192.168.101.0/24)
	echo $test3
	echo $test3 >> test-subnet101
	echo 'All is done ! '

	echo 'Fin du script, bye ! '
	exit

## Fin de script si aucun parametre spécifié.

else
	echo 'Aucun ou mauvais parametre spécifié, fin du script ! '
	echo 'Bye !'
	exit

fi

#
