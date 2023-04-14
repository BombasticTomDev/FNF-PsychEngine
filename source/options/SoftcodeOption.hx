package options;

class SoftcodeOption extends Option
{
    private var emulatedValue:Dynamic = null;
    
    override function getValue():Dynamic {
        return emulatedValue;
    }

    override function setValue(value:Dynamic) {
        return emulatedValue = value;
    }

    public function reloadOption(type:String){
		this.type = type;

		switch(type)
		{
			case 'bool':
				defaultValue = false;
			case 'int' | 'float':
				defaultValue = 0;
		    case 'percent':
				defaultValue = 1;
			case 'string':
				options = [''];
                defaultValue = '';
            }

        setValue(defaultValue);
    }
}