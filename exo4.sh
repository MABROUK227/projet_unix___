#!/bin/bash

# Fonction pour définir les politiques par défaut
set_default_policy() {
    echo "Configuration des politiques par défaut"
    read -p "Politique par défaut pour INPUT (ACCEPT/DROP) : " input_policy
    read -p "Politique par défaut pour OUTPUT (ACCEPT/DROP) : " output_policy
    read -p "Politique par défaut pour FORWARD (ACCEPT/DROP) : " forward_policy

    iptables -P INPUT $input_policy
    iptables -P OUTPUT $output_policy
    iptables -P FORWARD $forward_policy

    echo "Politiques par défaut configurées."
}

# Ajouter une règle
add_rule() {
    read -p "Chaîne (INPUT/OUTPUT/FORWARD) : " chain
    read -p "Protocole (tcp/udp) : " protocol
    read -p "Port : " port
    read -p "Adresse IP source (ou laisser vide) : " src_ip
    read -p "Adresse IP destination (ou laisser vide) : " dest_ip
    read -p "Action (ACCEPT/DROP) : " action

    iptables -A $chain -p $protocol --dport $port -s $src_ip -d $dest_ip -j $action
    echo "Règle ajoutée."
}

# Modifier une règle
modify_rule() {
    read -p "Numéro de la règle à modifier : " rule_num
    read -p "Chaîne (INPUT/OUTPUT/FORWARD) : " chain
    read -p "Protocole (tcp/udp) : " protocol
    read -p "Port : " port
    read -p "Adresse IP source (ou laisser vide) : " src_ip
    read -p "Adresse IP destination (ou laisser vide) : " dest_ip
    read -p "Action (ACCEPT/DROP) : " action

    # Vérification de l'action
    if [[ "$action" != "ACCEPT" && "$action" != "DROP" ]]; then
        echo "Action invalide. Veuillez entrer ACCEPT ou DROP."
        return
    fi

    # Commande iptables avec l'action
    if [[ -z "$dest_ip" ]]; then
        # Si aucune adresse IP de destination n'est spécifiée
        iptables -R "$chain" "$rule_num" -p "$protocol" --dport "$port" -s "$src_ip" -j "$action"
    else
        # Si une adresse IP de destination est spécifiée
        iptables -R "$chain" "$rule_num" -p "$protocol" --dport "$port" -s "$src_ip" -d "$dest_ip" -j "$action"
    fi

    echo "Règle modifiée."
}

# Supprimer une règle
delete_rule() {
    read -p "Chaîne (INPUT/OUTPUT/FORWARD) : " chain
    read -p "Numéro de la règle à supprimer : " rule_num

    iptables -D $chain $rule_num
    echo "Règle supprimée."
}

# Gestion des règles de pare-feu
manage_rules() {
    echo "Gestion des règles de pare-feu"
    echo "1. Ajouter une règle"
    echo "2. Modifier une règle"
    echo "3. Supprimer une règle"
    read -p "Choisissez une option : " choice

    case $choice in
        1)
            add_rule
            ;;
        2)
            modify_rule
            ;;
        3)
            delete_rule
            ;;
        *)
            echo "Option invalide"
            ;;
    esac
}

# Activer NAT
enable_nat() {
    read -p "Interface réseau pour NAT (ex: eth0) : " interface
    iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
    echo "NAT activé."
}

# Ajouter une redirection de port
add_port_forward() {
    read -p "Port source : " src_port
    read -p "Adresse IP de destination : " dest_ip
    read -p "Port destination : " dest_port

    iptables -t nat -A PREROUTING -p tcp --dport $src_port -j DNAT --to-destination $dest_ip:$dest_port
    echo "Redirection de port ajoutée."
}

# Supprimer une redirection de port
delete_port_forward() {
    read -p "Port source : " src_port
    read -p "Adresse IP de destination : " dest_ip
    read -p "Port destination : " dest_port

    # Supprimer la redirection de port avec les informations fournies
    iptables -t nat -D PREROUTING -p tcp --dport $src_port -j DNAT --to-destination $dest_ip:$dest_port

    echo "Redirection de port supprimée."
}

# Gestion des règles NAT
manage_nat() {
    echo "Gestion des règles NAT"
    echo "1. Activer NAT (masquerading)"
    echo "2. Ajouter une redirection de port"
    echo "3. Supprimer une redirection de port"
    read -p "Choisissez une option : " choice

    case $choice in
        1)
            enable_nat
            ;;
        2)
            add_port_forward
            ;;
        3)
            delete_port_forward
            ;;
        *)
            echo "Option invalide"
            ;;
    esac
}

# Activer la journalisation
enable_logging() {
    read -p "Chaîne (INPUT/OUTPUT) : " chain
    iptables -A $chain -j LOG --log-prefix "Journal pare-feu: "
    echo "Journalisation activée."
}

# Désactiver la journalisation
disable_logging() {
    read -p "Chaîne (INPUT/OUTPUT) : " chain

    # Vérifier si une règle de LOG existe dans la chaîne
    if iptables -L $chain | grep -q "LOG"; then
        iptables -D $chain -j LOG
        echo "Journalisation désactivée."
    else
        echo "Aucune règle de journalisation trouvée dans la chaîne $chain."
    fi
}

# Gestion de la journalisation
manage_logging() {
    echo "Gestion de la journalisation"
    echo "1. Activer la journalisation"
    echo "2. Désactiver la journalisation"
    read -p "Choisissez une option : " choice

    case $choice in
        1)
            enable_logging
            ;;
        2)
            disable_logging
            ;;
        *)
            echo "Option invalide"
            ;;
    esac
}

# Générer un rapport des règles actuelles
generate_report() {
    echo "Rapport des règles de pare-feu"
    iptables -L -v -n
}

# Menu principal
main_menu() {
    while true; do
        echo "-------------------------"
        echo "1. Configurer les politiques par défaut"
        echo "2. Gérer les règles de pare-feu"
        echo "3. Gérer les règles NAT"
        echo "4. Gérer la journalisation"
        echo "5. Générer un rapport"
        echo "6. Quitter"
        echo "-------------------------"
        read -p "Choisissez une option : " choice

        case $choice in
            1)
                set_default_policy
                ;;
            2)
                manage_rules
                ;;
            3)
                manage_nat
                ;;
            4)
                manage_logging
                ;;
            5)
                generate_report
                ;;
            6)
                echo "Au revoir!"
                exit 0
                ;;
            *)
                echo "Option invalide, veuillez réessayer."
                ;;
        esac
    done
}

# Exécuter le menu principal
main_menu
