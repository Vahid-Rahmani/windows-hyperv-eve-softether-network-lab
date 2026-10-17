# Mein Windows Server Projekt mit zwei Standorten

Ich habe mit einem kleinen Windows Server Lab unter Hyper-V angefangen. Die Verbindung zu EVE-NG auf einem zweiten Rechner war deutlich schwieriger als die Verbindung zwischen den ersten VMs. Daraus ist Schritt für Schritt eine größere Umgebung geworden.

Heute enthält mein Aufbau zwei Standorte, sechs VLANs, Active Directory, Dateidienste, einen Dateiservercluster und ein eigenes Monitoring-Dashboard. Die Windows-Seite läuft unter Hyper-V. Unter Linux verwende ich KVM und virt-manager. Router und Switches laufen in EVE-NG.

[Mein Bericht als PDF, 15 Seiten](reports/Abschlussprojekt_Vahid_Rahmani_DE.pdf) · [Vollständige Topologie](../assets/two-site-topology.png)

## Warum ich weitergebaut habe

Die Kursaufgaben behandeln einzelne Dienste wie AD, Freigaben, GPOs, Verschlüsselung und Backup. Ich wollte auch verstehen, wie diese Dienste über mehrere Netze zusammenarbeiten. Deshalb habe ich den zweiten Standort und den gemeinsamen Speicher ergänzt.

Die Kursvorlage verwendet techwork.local. Mein größerer Aufbau verwendet kurs.intern. Ich habe die Funktionen der Aufgaben übernommen und die tatsächlichen Namen und Adressen meines Labs dokumentiert.

## Windows und Linux verbinden

Auf Windows verwende ich den internen Hyper-V-Switch DC-LAB. SoftEther verbindet diesen Bereich mit br-eve unter Linux. Von dort geht der Weg in das EVE-NG-Netz.

Dabei musste ich Transport und Routing trennen. SoftEther überträgt Ethernet-Daten. R1 ist das Gateway der VLANs. Ein laufender SoftEther-Dienst allein beweist deshalb noch keine Verbindung zwischen den Windows-Servern.

Die Bridge zeigte Operating und die Cascade Online (Established). Danach wurde die Verbindung weiter geprüft. Der dokumentierte Ping von R1 zum Haupt-DC 192.168.10.10 hatte fünf von fünf Antworten.

## Die Fehlersuche gehört zum Projekt

Ein Problem war die doppelte Adresse 192.168.10.1. Sie war auch auf dem Hyper-V-Host vorhanden. Ein Ping konnte deshalb von Windows statt vom Router beantwortet werden. Erst der Vergleich der MAC-Adressen hat das deutlich gemacht. Für den Host wurde .254 vorgesehen; R1 behält .1.

Bei einem anderen Fehler waren die Ports up, aber die erwarteten Daten fehlten. Ich habe ARP, die MAC-Tabelle und Paket-Zähler geprüft. Mit tcpdump auf br-eve konnte ich Anfragen aus Hyper-V sehen. So wurde der Bereich für die weitere Suche kleiner.

Auch bei DHCP reichte ein aktiver Bereich nicht aus. Relay, Routeroption und Rückweg mussten zusammenpassen. Seitdem prüfe ich eine Clientadresse immer zusammen mit Gateway und DNS.

## Der Cluster am zweiten Standort

TW-CL1 und TW-CL2 sind meine beiden Clusterknoten. TW-STOR1 stellt den iSCSI-Speicher bereit. Der Aufbau verwendet einen Datenträger mit 5 GB und einen Witness mit 1 GB auf einem 10 GB großen Datenlaufwerk.

TW-FS01 hat die Adresse 192.168.40.20. Die Clusterverwaltung TW-CLUSTER hat 192.168.40.25. Diese Namen stehen für virtuelle Dienste, nicht für zwei weitere VMs.

Auch hier musste ich die Begriffe erst sauber trennen. Gemeinsame Disks werden einmal vorbereitet und danach vom Cluster verwaltet. Ein Disk Witness ist keine Sicherung der Benutzerdateien. Ein Ausfall des physischen Linux-Rechners oder des einzelnen Storage-Servers bleibt eine Grenze des Aufbaus.

## Das Dashboard zeigt auch die offenen Punkte

Meine Screenshots zeigen zehn bekannte Geräte und Messwerte für neun. CLI-01 antwortet nicht auf die WinRM-Prüfung. Daraus kann ich noch nicht schließen, dass der Client ausgeschaltet ist.

Der SMB-Endpunkt von TW-FS01 ist erreichbar. Der Zustand der Clusterrolle TW-CLUSTER ist in dieser Ansicht nicht bestätigt. Eine grüne Portprüfung ist kein Dateizugriff und kein Failover-Test.

Der Anwendungscode liegt im separaten [Monitoring-Repository](https://github.com/Vahid-Rahmani/Automated-Hybrid-Network-Monitoring-Dashboard). Die Bilder hier zeigen den lokalen Lauf für meinen Projektbericht.

## Was ich aus der Arbeit mitnehme

Für mich war der größte Fortschritt, Fehler nach ihrem Weg im Netz zu untersuchen. Eine falsche Gateway-Adresse lässt sich nicht mit einer neuen DNS-Einstellung lösen. Ein offener Port bestätigt nicht alle Funktionen eines Dienstes. Und ein erfolgreicher Backup-Lauf ist noch kein Test der Wiederherstellung.

Ein aktueller Replikationsbericht, automatischer Failover mit Dateizugriff und ein Restore-Test brauchen noch ihre eigenen Nachweise im Repository. Ich möchte zeigen, was ich gebaut und verstanden habe, ohne mein Lernprojekt als vollständig geprüfte Produktionsumgebung darzustellen.

Die ältere Version bleibt in den früheren Notizen und unter [docs/archive](archive/) erhalten. So lässt sich der Weg vom ersten Verbindungsproblem bis zum heutigen Aufbau nachvollziehen.

Vahid Rahmani · Stand 17. Oktober 2026
