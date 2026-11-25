// Writes fooyin's QSettings file, including a FyTheme variant.
// The theme is a Qt metatype, so it has to be serialised by the same Qt build
// that fooyin uses instead of being written by hand in Nix.

#include <QCoreApplication>
#include <QDataStream>
#include <QFile>
#include <QFont>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QMetaEnum>
#include <QMetaType>
#include <QPalette>
#include <QSettings>

#include <cstdio>
#include <optional>

namespace Fooyin {
struct PaletteKey
{
    QPalette::ColorRole role;
    QPalette::ColorGroup group{QPalette::All};

    bool operator==(const PaletteKey& other) const = default;

    bool operator<(const PaletteKey& other) const
    {
        if(role < other.role) {
            return true;
        }
        if(role > other.role) {
            return false;
        }
        return group > other.group;
    }

    friend QDataStream& operator<<(QDataStream& stream, const PaletteKey& key)
    {
        stream << key.group;
        stream << key.role;
        return stream;
    }

    friend QDataStream& operator>>(QDataStream& stream, PaletteKey& key)
    {
        stream >> key.group;
        stream >> key.role;
        return stream;
    }
};

struct FyTheme
{
    int id{0};
    QString name;
    int index{0};
    bool isDefault{false};
    QMap<PaletteKey, QColor> colours;
    QMap<QString, QFont> fonts;

    bool operator==(const FyTheme& other) const = default;

    friend QDataStream& operator<<(QDataStream& stream, const FyTheme& theme)
    {
        stream << 1;
        stream << theme.id;
        stream << theme.index;
        stream << theme.name;
        stream << theme.isDefault;
        stream << theme.colours;
        stream << theme.fonts;
        return stream;
    }

    friend QDataStream& operator>>(QDataStream& stream, FyTheme& theme)
    {
        int version{0};
        stream >> version;
        stream >> theme.id;
        stream >> theme.index;
        stream >> theme.name;
        stream >> theme.isDefault;
        stream >> theme.colours;
        stream >> theme.fonts;
        return stream;
    }
};
} // namespace Fooyin

Q_DECLARE_METATYPE(Fooyin::PaletteKey)
Q_DECLARE_METATYPE(Fooyin::FyTheme)

namespace {
std::optional<QPalette::ColorGroup> groupFromName(const QString& name)
{
    if(name == QStringLiteral("active")) {
        return QPalette::Active;
    }
    if(name == QStringLiteral("disabled")) {
        return QPalette::Disabled;
    }
    if(name == QStringLiteral("inactive")) {
        return QPalette::Inactive;
    }
    if(name == QStringLiteral("all")) {
        return QPalette::All;
    }
    return {};
}

std::optional<QPalette::ColorRole> roleFromName(const QString& name)
{
    const auto meta = QMetaEnum::fromType<QPalette::ColorRole>();

    bool ok{false};
    const int value = meta.keyToValue(name.toLatin1().constData(), &ok);
    if(!ok) {
        return {};
    }
    return static_cast<QPalette::ColorRole>(value);
}

QByteArray savedThemes(const Fooyin::FyTheme& theme)
{
    QByteArray data;
    QDataStream stream{&data, QIODevice::WriteOnly};
    stream.setVersion(QDataStream::Qt_6_0);

    stream << 1;
    stream << theme;

    return qCompress(data, 9);
}
} // namespace

int main(int argc, char** argv)
{
    if(argc != 3) {
        std::fprintf(stderr, "usage: theme-writer <fooyin.conf> <theme.json>\n");
        return 1;
    }

    QCoreApplication app{argc, argv};
    qRegisterMetaType<Fooyin::FyTheme>("Fooyin::FyTheme");
    qRegisterMetaType<Fooyin::PaletteKey>("Fooyin::PaletteKey");

    QFile input{QString::fromLocal8Bit(argv[2])};
    if(!input.open(QIODevice::ReadOnly)) {
        std::fprintf(stderr, "cannot read %s\n", argv[2]);
        return 1;
    }

    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(input.readAll(), &error);
    if(error.error != QJsonParseError::NoError || !document.isObject()) {
        std::fprintf(stderr, "invalid theme JSON: %s\n", error.errorString().toLocal8Bit().constData());
        return 1;
    }

    const auto root = document.object();

    Fooyin::FyTheme theme;
    theme.id        = root.value(QStringLiteral("id")).toInt(100);
    theme.index     = root.value(QStringLiteral("index")).toInt(theme.id);
    theme.name      = root.value(QStringLiteral("name")).toString(QStringLiteral("NixConfig"));
    theme.isDefault = false;

    const auto colours = root.value(QStringLiteral("colours")).toArray();
    for(const auto& value : colours) {
        const auto entry = value.toObject();

        const auto group = groupFromName(entry.value(QStringLiteral("group")).toString());
        const auto role  = roleFromName(entry.value(QStringLiteral("role")).toString());
        QString colourName = entry.value(QStringLiteral("colour")).toString();
        if(!colourName.startsWith(QLatin1Char('#'))) {
            colourName.prepend(QLatin1Char('#'));
        }
        const QColor colour{colourName};

        if(!group || !role || !colour.isValid()) {
            std::fprintf(stderr, "invalid colour entry\n");
            return 1;
        }

        theme.colours.insert({Fooyin::PaletteKey{*role, *group}}, colour);
    }

    const auto fontConfig = root.value(QStringLiteral("font")).toObject();
    const QString fontFamily = fontConfig.value(QStringLiteral("family")).toString();
    if(!fontFamily.isEmpty()) {
        QFont font{fontFamily};
        const double pointSize = fontConfig.value(QStringLiteral("size")).toDouble(10.5);
        font.setPointSizeF(pointSize > 0.0 ? pointSize : 10.5);
        theme.fonts.insert(QString{}, font);
    }

    QSettings settings{QString::fromLocal8Bit(argv[1]), QSettings::IniFormat};
    settings.setValue(QStringLiteral("Theme/CustomTheme"), QVariant::fromValue(theme));
    settings.setValue(QStringLiteral("Theme/SavedThemes"), savedThemes(theme));

    settings.sync();

    if(settings.status() != QSettings::NoError) {
        std::fprintf(stderr, "cannot write fooyin config\n");
        return 1;
    }

    return 0;
}
