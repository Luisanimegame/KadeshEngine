package animateatlas;

import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.Assets;
import haxe.Json;
import openfl.display.BitmapData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.AnimationData;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFrame.FlxFrameCollectionType; // IMPORT CORRETO
import flixel.util.FlxColor;

using StringTools;

class AtlasFrameMaker
{
    public static function construct(key:String, ?_excludeArray:Array<String> = null, ?noAntialiasing:Bool = false):FlxFramesCollection
    {
        var frameArray:Array<Array<FlxFrame>> = [];

        // Verifica formato antigo
        if (Paths.fileExists('images/$key/spritemap1.json', TEXT))
        {
            trace("ERRO: Apenas spritemaps do Adobe Animate 2020+ (Animation.json + spritemap.json) são suportados.");
            return null;
        }

        // Carrega JSONs
        var animationData:AnimationData = null;
        var atlasData:AtlasData = null;
        try {
            animationData = Json.parse(Paths.getTextFromFile('images/$key/Animation.json'));
            var atlasText = Paths.getTextFromFile('images/$key/spritemap.json');
            if (atlasText != null) atlasText = atlasText.replace("\uFEFF", "");
            atlasData = Json.parse(atlasText);
        }
        catch (e:Dynamic) {
            trace('Erro ao ler JSON do atlas: $key | $e');
            return null;
        }

        // Carrega imagem
        var graphic:FlxGraphic = Paths.image('$key/spritemap');
        if (graphic == null || graphic.bitmap == null)
        {
            trace('Imagem não encontrada: $key/spritemap.png');
            return null;
        }

        // Cria animação
        var ss = new SpriteAnimationLibrary(animationData, atlasData, graphic.bitmap);
        var t:SpriteMovieClip = ss.createAnimation(noAntialiasing);

        // Animações a incluir
        if (_excludeArray == null || _excludeArray.length == 0)
            _excludeArray = t.getFrameLabels();

        trace('Criando animações: $_excludeArray');

        // Cria coleção → TIPO CORRETO
        var framesCollection = new FlxFramesCollection(graphic, FlxFrameCollectionType.USER);

        // Extrai frames
        for (anim in _excludeArray)
        {
            var animFrames = getFramesArray(t, anim);
            if (animFrames != null)
                frameArray.push(animFrames);
        }

        // Adiciona todos os frames
        for (animFrames in frameArray)
        {
            for (frame in animFrames)
            {
                framesCollection.pushFrame(frame);
            }
        }

        // NÃO DESTROI t → gerenciado pela biblioteca
        return framesCollection;
    }

    @:noCompletion
    static function getFramesArray(t:SpriteMovieClip, animation:String):Array<FlxFrame>
    {
        if (t == null || animation == null) return [];

        t.currentLabel = animation;
        var bitmaps:Array<BitmapData> = [];
        var frames:Array<FlxFrame> = [];
        var first:Bool = true;
        var frameSize:FlxPoint = FlxPoint.get();

        var start = t.getFrame(animation);
        if (start < 0) start = 0;

        for (i in start...t.numFrames)
        {
            t.currentFrame = i;
            if (t.currentLabel != animation) break;

            var bounds = t.getBounds(t);
            if (bounds.width <= 0 || bounds.height <= 0) continue;

            var bmp = new BitmapData(Std.int(bounds.width + bounds.x), Std.int(bounds.height + bounds.y), true, 0);
            bmp.draw(t, null, null, null, null, true);
            bitmaps.push(bmp);

            if (first)
            {
                frameSize.set(bmp.width, bmp.height);
                first = false;
            }
        }

        // Converte para FlxFrame
        for (i in 0...bitmaps.length)
        {
            var bmp = bitmaps[i];
            var graphic = FlxGraphic.fromBitmapData(bmp, false, null, false);
            graphic.persist = true;
            graphic.destroyOnNoUse = false;

            var frame = new FlxFrame(graphic);
            frame.parent = graphic;
            frame.name = animation + '_' + i;
            frame.sourceSize.set(frameSize.x, frameSize.y);
            frame.frame = FlxRect.get(0, 0, bmp.width, bmp.height);
            frames.push(frame);
        }

        // Limpa bitmaps
        for (bmp in bitmaps)
            if (bmp != null) bmp.dispose();
        bitmaps = null;
        frameSize.put();

        return frames;
    }
}