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
import flixel.graphics.frames.FlxFrame.FlxFrameCollectionType;
import flixel.util.FlxColor;

using StringTools;

class AtlasFrameMaker extends FlxFramesCollection
{
    /**
     * Cria frames a partir de um Texture Atlas do Adobe Animate.
     * @param key Caminho da pasta (ex: 'characters/BOYFRIEND')
     * @param _excludeArray Animações a incluir (ou null para todas)
     * @param noAntialiasing Desativa antialiasing
     * @return FlxFramesCollection ou null se falhar
     */
    public static function construct(key:String, ?_excludeArray:Array<String> = null, ?noAntialiasing:Bool = false):FlxFramesCollection
    {
        var frameCollection:FlxFramesCollection;
        var frameArray:Array<Array<FlxFrame>> = [];

        if (Paths.fileExists('images/$key/spritemap1.json', TEXT))
        {
            trace("ERRO: Spritemaps do Adobe Animate 2018+ não são suportados aqui.");
            return null;
        }

        var animationData:AnimationData = null;
        var atlasData:AtlasData = null;

        try {
            var animText = Paths.getTextFromFile('images/$key/Animation.json');
            var atlasText = Paths.getTextFromFile('images/$key/spritemap.json');
            if (atlasText != null) atlasText = atlasText.replace("\uFEFF", ""); // Remove BOM

            animationData = Json.parse(animText);
            atlasData = Json.parse(atlasText);
        }
        catch (e:Dynamic) {
            trace('Falha ao carregar JSON do atlas: $key | Erro: $e');
            return null;
        }

        var graphic:FlxGraphic = Paths.image('$key/spritemap');
        if (graphic == null || graphic.bitmap == null)
        {
            trace('Falha ao carregar imagem: $key/spritemap.png');
            return null;
        }

        var ss = new SpriteAnimationLibrary(animationData, atlasData, graphic.bitmap);
        var t = ss.createAnimation(noAntialiasing);

        if (_excludeArray == null || _excludeArray.length == 0)
        {
            _excludeArray = t.getFrameLabels();
        }

        trace('Criando animações do atlas: $_excludeArray');

        // Cria coleção de frames
        frameCollection = new FlxFramesCollection(graphic, FlxFrameCollectionType.USER);

        for (animName in _excludeArray)
        {
            var frames = getFramesArray(t, animName);
            if (frames != null)
                frameArray.push(frames);
        }

        // Adiciona todos os frames
        for (frames in frameArray)
        {
            for (frame in frames)
            {
                frameCollection.pushFrame(frame);
            }
        }

        // Limpeza
        FlxDestroyUtil.destroy(t);
        return frameCollection;
    }

    /**
     * Extrai frames de uma animação específica.
     */
    @:noCompletion
    static function getFramesArray(t:SpriteMovieClip, animation:String):Array<FlxFrame>
    {
        if (t == null || animation == null || animation.length == 0)
            return [];

        t.currentLabel = animation;
        var bitMapArray:Array<BitmapData> = [];
        var daFramez:Array<FlxFrame> = [];
        var firstPass:Bool = true;
        var frameSize:FlxPoint = FlxPoint.get();

        var startFrame:Int = t.getFrame(animation);
        if (startFrame < 0) startFrame = 0;

        for (i in startFrame...t.numFrames)
        {
            t.currentFrame = i;
            if (t.currentLabel != animation)
                break;

            var bounds:Rectangle = t.getBounds(t);
            if (bounds.width <= 0 || bounds.height <= 0)
                continue;

            var bitmap:BitmapData = new BitmapData(
                Std.int(bounds.width + bounds.x),
                Std.int(bounds.height + bounds.y),
                true, 0
            );
            bitmap.draw(t, null, null, null, null, true);
            bitMapArray.push(bitmap);

            if (firstPass)
            {
                frameSize.set(bitmap.width, bitmap.height);
                firstPass = false;
            }
        }

        for (i in 0...bitMapArray.length)
        {
            var bmp = bitMapArray[i];
            var graphic = FlxGraphic.fromBitmapData(bmp, false, null, false);
            graphic.persist = true;
            graphic.destroyOnNoUse = false;

            var frame = new FlxFrame(graphic);
            frame.parent = graphic;
            frame.name = animation + i;
            frame.sourceSize.set(frameSize.x, frameSize.y);
            frame.frame = FlxRect.get(0, 0, bmp.width, bmp.height);
            daFramez.push(frame);
        }

        for (bmp in bitMapArray)
        {
            FlxDestroyUtil.dispose(bmp);
        }
        bitMapArray = null;
        frameSize.put();

        return daFramez;
    }
}