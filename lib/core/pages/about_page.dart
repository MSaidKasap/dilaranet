// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String htmlContent = '''

      <!DOCTYPE html>
      <html>
<head>
  <style>
    img {
      display: block;
      margin-left: auto;
      margin-right: auto;
    }
  </style>
</head>
<body>

<img class="size-medium wp-image-110 alignleft" src="https://www.dilara.net/wp-content/uploads/muellif-250x300.png" alt="" width="250" height="300" />

<h2><strong>İsmail Çetin Hoca Efendi</strong> </h2>
27 Şubat 1942 yılında bir Cuma günü <strong>Diyarbakır</strong>‘ın <strong>Hazro</strong> kazasında doğdu. Babası molla lakablı <strong>Mahfuz’</strong>dur. İsmail ismi Molla Mahfuz’un örfi olarak dede isimlerinden çektiği kur’a sonucu beşinci babası olan <strong>Hace İsmail Hakkı Zûri </strong>efendinin ismidir. Dedesi <strong>Kadı Beydavî</strong> üzerine bir haşiyesi bulunan <strong>Molla Süleyman</strong>‘dır. Annesi Mesabih’i şerh eden büyük âlimlerden olan Molla Reşid’in kızı <strong>Râbia</strong> hanımdır. Babasının annesi o zamanın Diyarbakır kadısı Ahmed Efendi’nin kızı, anneannesi ise zamanın meşhur şeyhlerinden Mevlâna Hâlid’in halîfelerinden Şeyh Salih Sîbkî’nin halifesi İbrahim Bahçevî’nin kızıdır.

İlk dini terbiyesini, <strong>Kürtçe Amentü şerhini </strong>ve vel-l-Fecri’ye kadar <strong>Kur’an’ı Kerîm</strong>‘i annesinden öğrendi. Annesi beş yaşında iken Perşembe gününe denk gelen bir kurban bayramında vefat etti.

İlme başlamadan önce babası Molla Mahfuz’un “<strong>Oğlum, amca oğlu Molla Haydar Hatiboğlu, Molla Nazif, Molla Muhammed, Molla İsmail Hakkı.. abilerin gibi ol.</strong>” tavsiyesine uyarak ilim tahsiline Hazro ile Lice arasında bulunan Entak köyündekıraat ilmine ait olan <strong>Ğâyet-ul-İhtisar</strong> adlı manzumeyi okuyarak başladı.

Lice’dededesi Molla Süleyman’ın talebelerinde ilim tahsiline devam etti. Daha sonra Hazro’yadönerek <strong>Molla Derviş</strong>‘te Bina, Maksud, Avamil, Cürcani ezberledi. Seyda HacıFettah’ın talebesi olan <strong>Molla Halid</strong>‘de, Zurûf, Terkib ve Küçük Sadullah’ın bir kısmınıbitirdi. <strong>Minhac</strong>‘ı -ki Şafi mezhebine aid bir fıkıh kitabıdır- feraiz babına kadar okuyarakezberledi. Daha sonra Hudur = Huzur köyünde<strong>Muhammed Hace Sıddık’</strong>tabir sene zarfında Kur’an-ı Kerim’den itibaren öğrenmiş olduğu bütün ilimleri tekraretti.

Daha sonra <strong>Halep</strong> ve <strong>Şam’</strong>da bulunan âlimlerden kıraat okuyarak beş kıraattenicaze aldı, senetleriyle birlikte birçok hadis ezberledi. 14 yaşında Türkiye’ye dönüşündeÇınar ilçesine bağlı Has köyündeki amcasının dünürü olan <strong>Molla Mahmud’</strong>da Hal ve Sâdullah kitablarını kısa bir sürede bitirdi.

Daha sonra Siirt’te bulunanKayser Camisi imamlarından <strong>Üstad Tayyib</strong>‘de Netaic-ul-Efkar’ı ve metin ezberlerinitamamladı. Siirt’ten Tillo’ya giderek <strong>Seyda Halil</strong>‘de nahiv ilminden Suyuti ve Molla Câmi kitablarını, <strong>Üstad Bedreddin</strong>‘den ise münazara ilminden Veledî ve şerhleriniokudu. İki sene burada kaldıktan sonra, mantık, belâğat, istiâre, vadı’, âdab, münazara,bir kısım felsefe ve kelam ilimlerini <strong>Şeyh Nesim Küfrevî Efendi</strong> ve <strong>Şeyh Muhammed Şefik Arvâsî</strong> Efendi’nin talebelerinden olan <strong>Patnoslu Üstad Molla Yasin</strong>‘in yanındaokuyarak tamamladı ve ilk ilim icâzesini aldı.

Daha sonra Ağrı’nın Balivarköyünde <strong>Molla Hasan</strong>‘dan mantık ve tefsir dersleri aldı, talim ve tecvidde Molla Hasan’aders verdi. Sekiz ay Erzurum’da <strong>Sakıp Efendi</strong>‘den kelam dersleri aldı. Şirvan’da<strong> Molla Muhammed Kasım</strong>‘ın yanında altı ay tahsiline devam ederek icazealdı.

O zamanın Diyanet reisi <strong>Ömer Nasuhi Bilmen</strong>‘in ziyaretinde bulunarak onunyanında <strong>Muvazzah İlm-i Kelam</strong> kitabını okudu, <strong>Üstad Molla Muhammed Zivingî</strong>‘ninyanında da bir dönem okuyarak icaze aldı.

Ayrıca devrin büyük alimlerinden<strong> Abdurrahman Buluntu Efendi</strong>nin yanında altı ay kalarak tefsir kitabı <strong>Kadı Beydâvi</strong>‘den icaze aldı. Bunlardan başka <strong>Üstad Molla Ca’fer, Of’ta Abdurrahman Efendi, İstanbul’da Gönenli Mehmet Efendi, Çelebi Mehmet Efendi, Muhammed Şefik Arvâsî Efendi</strong> ve zamanın Sultan Ahmed Câmîsi’nin imamlarına varıncaya kadarişittiği her ilim adamını ziyaret etti.

Aynı zamanda <strong>Üstad Necip Fazıl’ı</strong> sık sık ziyaretederek fikir alışverişinde bulundu. Bütün bu ziyaretlerinin sebebi de Üstadı MollaYasin ve Molla Abdulfettah’ın işaretiyle olmuştur.

Bu sayılanlar arasında üç gündendaha az görüştüğü ve hizmetinde bulunduğu zatları saymıyoruz. Sayılanlar dışındakendisinin de kabul ettiği 60’ın üstünde ulema 100’ün üzerinde meşayıhla görüşmüştür.

Ve ayrıca talebeyken hocalarıyla yapmış olduğu bir seyahatte B<strong>ediüzzaman Saîd Nursî Hazretlerini </strong>iki kere Isparta’da ziyaret etti. Daha sonra ilki Bilvanis olmak üzere çeşitli yerlerde <strong>Seyyid Abdulhakim el-Hüseynî</strong> (Ğavs) Hazretlerinin emriyle müderrislik yaptı.

Tasavvufi olarak ilk dersini 7 yaşında Norşinli <strong>Şeyh Ma’şûk</strong>‘dan aldı. Gençlik döneminde <strong>Seyyid Abdulhakim el-Hüseynî</strong> hazretlerine intisab etti, bir dönem vekilliğini yaptı. Onun yanında amelini tamamladı, hilafet aldı. Ğavs Hazretleri ömrünün sonlarında hilafetini ilan için yanına çağırdı, fakat müftülükten izin alamadığı için ancak vefatından bir müddet sonra yetişebildi.

Ğavs’ın halifesi olduğunu fitneye sebebiyet vermemek için ömrü boyunca gizledi. İsmail Çetin Hoca Efendi 1973 yılında intisab ettiği Medineli <strong>Şeyh Abdulğafûr el-Abbasi</strong> hazretlerinin oğlu <strong>Şeyh Abdulhak hazretlerinden</strong> 1976 yılında hac mevsiminde Nakşibendî, Kâdiri, Kübrevî, Sühreverdi ve Çiştiyye tarikatlerinden ve 2000 yılında Kadiri şeyhlerinden olan kayınbabası <strong>Şeyh Muhammed Ma’sûm</strong>hazretlerinden hilafet aldı.

Askerliğini Sivas, Kayseri İncidere, Ağrı Kösedağ ve Erzurum Sarıkamış’ta (1967 Nisan ayında) tamamladı. Terhis olduktan sonra Diyarbakır’a döndü, aynı yılın Kasım ayında <strong>Şeyh Muhammed Sadaka</strong>‘nın halifesi ve aynı zamanda dayısı Şeyh Muhammed Ma’sûm’un kızı ile evlendi.

Bir dönem Diyarbakır’da kitapçılık yaparken Diyarbakır’ın <strong>Ka’bî</strong> köyünde imamlık ve müderrisliğe başladı. Yine Ğavs Hazretlerinin emriyle 1971 senesinde <strong>Isparta’</strong>nın <strong>Göndürle</strong> (Harmanören) köyünde ve <strong>Atabey</strong> ilçesinde bir müddet imamlık yaptıktan sonra istifa ederek Isparta’ya yerleşti. <strong>Dilara Yayınları</strong> adı altında te’lifata başladı. Daha sonra Dilara Yayıncılık olarak kitab ve kırtasiye dükkânı açıp eserlerini neşretmeye başladı.

1996 yılında sağlık sorunlarından dolayı Antalya’nın <strong>Aksu</strong> ilçesine göç ederek ilmi çalışmalarını hayatının sonuna kadar burada devam ettirdi. 1980 ihtilalinde kendi tabiriyle <strong>Medrese-i Yûsufiyye</strong>‘de yakalandığı astım ve bronşit sebebiyle zaman içerisinde <strong>Koah hastalığına</strong> yakalandı, 2000 yılından sonra hastalığı şiddetlendi, son olarak 9 Mayıs 2011 tarihinde ani kalb durması(ventriculer fibrilasyon) sonucu kaldırıldığı Isparta Gülkent hastanesinin yoğun bakım ünitesinde <strong>17 Haziran 2011</strong> (Hicri 15 Receb 1432) de yine doğduğu Cuma günü sabah namazı vaktinde Allah Teâlâ’ya kavuştu. Isparta’da kendi temelini atıp hizmete sunduğu cami ve külliyesinin yanındaki mezarlık da medfundur.

Bütün varlığını İslam ve gençlere vakfeden Üstad İsmail Çetin Hazretleri, İlmin vakarını, ağırlığını, tevazu kanatlarını yere germekle, hayatını <strong>Ehli Sünnet vel’Cemaat</strong> İ’tikadı’nı yaymaya, insanların kalblerine yerleştirmeye, yine Ehli Sünnet İ’tikadı’nın savunucusu olarak ilim, irşad ve bunların ışığı altında gençlerin yetişmelerine, iyi insan olmalarına ve iyi insan yetiştirmelerine adadı.

Hiçbir zaman şöhreti sevmeyen İsmail Çetin Hoca Efendi; “<strong>Şöhret başa beladır</strong>” diyerek şöhretten hayatı boyunca sakındı. Hastalığının en şiddetli zamanlarında dahi te’lifâtı ve tedrisâtı, Müslümanlarla hasbihal etmeyi asla bırakmadı. Hayatı boyunca insanların ihtiyaclarını, onlara hissettirmeden tesbit ederek özellikle gençlerin evlendirilmesi, borçluların borcunun giderilmesi, hastaların doktor, ilaç, ameliyat gibi ihtiyaçlarının karşılanması konusunda hassas davrandı.

<strong>Öğrenciden alınan ücretle ilmin bereketinin kalmayacağını söyleyerek yanına gelen öğrenci ve talebelerinden öğrettiği mukabilinde hiçbir surette ücret ve hediye kabul etmedi.</strong>

Vefatına kadar Ehli Sünnet vel’Cemaat dışında hiçbir zümrenin, partinin adamı olmadı. Müslümanların arasındaparti, meşreb, mezheb ayrımı gözetmeksizin her müslümanı kucakladı. EhliSünnet vel’Cemaatin savunucusu olarak yanına gelen Müslümanları Ehli Sünnete aykırı söz, fiil ve harekette bulunmadıkları müddetçe hilm ve şefkatle karşıladı. Bunun dışında gelen soru ve itirazları, yine Ehli Sünnet İ’tikadı içerisinde cevaplandırmaya ehemmiyet gösterdi. Birçok yerde öğrenci yurdu ve cami yapılmasına vesileoldu. Bunlardan iki cami ve bir öğrenci yurdunun çizimi, planı, projesi ve mimarisi kendisine aiddir. Hâlihazırda dünyanın çeşitli yerlerinde yetiştirmiş olduğu bir çok talebesi vardır.

İsmail Çetin Hoca Efendinin matbu ve matbu olmayan eserleri, ilerleyen günlerde çalışmaları tamamlandıkça yayınlanacaktır. Ayrıca hayatı Velinimetim Üstad İsmail Çetin ismiyle Şeyh Muhammed Said Çetin Efendi tarafından yayınlanmıştır.

Üstad İsmail Çetin Hocaefendi bu sırrı azîmi Şeyh Muhammed Said Çetin Efendi'ye tevdi ederek, 17 Haziran 2011 yılında dâr-ı bekâya irtihal etmiştir.
      </body>
      </html>
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hakkında"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Html(
          data: htmlContent,
        ),
      ),
    );
  }
}
